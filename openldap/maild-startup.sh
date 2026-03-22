#!/bin/bash
set -e

first_start_flag="/container/service/slapd/assets/certs/.first_start_done"

# Si ya existe el flag, saltar
if [ -f "$first_start_flag" ]; then
    echo "Provision de OpenLDAP para Maild realizada anteriormente... Saltando"
    exit 0
fi

template_file="/container/service/slapd/assets/config/bootstrap/ldif/custom/maild.ldif"
if [ ! -f "$template_file" ]; then
    echo "Ldif para provision de maild no encontrado: $template_file"
    exit 1
fi

echo "=== Provisionando OpenLDAP  para Maild ==="

# Renderizar template reemplazando {{VARIABLE}} por su valor
render_template() {
    perl -pe 's/\{\{([^}]+)\}\}/exists $ENV{$1} ? $ENV{$1} : $&/ge' "$1"
}

# Generar hash de contraseña dentro del contenedor
generate_hash() {
    local password="$1"
    slappasswd -s "$password"
}

# Verificar variables requeridas para setup
required_vars=(
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


ldif_content=$(render_template "$template_file")

# Generar ldif final
echo "$ldif_content" > $template_file

result=$?

if [ $result -eq 0 ]; then
    echo "✅ Setup inicial completado correctamente."
    echo "Usuario administrador: uid=$MAIL_ADMIN_USER,ou=people,$LDAP_BASE_DN"
    # Crear el flag para futuras ejecuciones
    touch "$first_start_flag"
    echo "Flag de primera ejecución creado en $first_start_flag"
else
    echo "❌ Error en el setup (código $result). Revise los logs."
    exit $result
fi
