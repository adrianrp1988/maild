#!/bin/bash
set -e

# Renderizar template reemplazando {{VARIABLE}} por su valor
render_template() {
    perl -pe 's/\{\{([^}]+)\}\}/exists $ENV{$1} ? $ENV{$1} : $&/ge' "$1"
}

# Generar hash de contraseña dentro del contenedor
generate_hash() {
    local password="$1"
    slappasswd -s "$password"
}


echo "=== Provisionando OpenLDAP ==="

# Verificar variables requeridas para setup
required_vars=(
    "LDAP_BASE_DN"
    "LDAP_ADMIN_DN"
    "MAIL_ADMIN_USER"
    "MAIL_ADMIN_PASSWORD"
)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Variable $var no definida en el entorno"
        exit 1
    fi
done

# Generar hash de la contraseña del admin
ADMIN_HASH=$(generate_hash "$MAIL_ADMIN_PASSWORD")
export ADMIN_HASH

# Renderizar template de config
template_file="./configure.ldif.template"
if [ ! -f "$template_file" ]; then
    echo "Error: No se encuentra $template_file"
    exit 1
fi
ldif_content=$(render_template "$template_file")

# Crear archivo temporal
echo "$ldif_content" > "/tmp/config.ldif"

# Ejecutar ldapmodify con EXTERNAL
echo "Aplicando configuración inicial..."
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/config.ldif
result=$?

# Limpiar
rm "/tmp/config.ldif"

if [ $result -eq 0 ]; then
    echo "✅ Setup completado correctamente."
    echo "Usuario administrador: uid=$MAIL_ADMIN_USER,ou=people,$LDAP_BASE_DN"
else
    echo "❌ Error en el setup (código $result). Revise los logs."
    exit $result
fi
