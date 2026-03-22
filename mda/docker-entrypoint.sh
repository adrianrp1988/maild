#!/bin/sh
set -e

if [ ! -f /etc/dovecot/configured ]; then
    # create the local config file
    CFILE=/etc/dovecot/config.local
    # Domain
    echo "DEFAULT_DOMAIN=${DEFAULT_DOMAIN}" > "${CFILE}"
    echo "COUNTRY=${COUNTRY}" >> ${CFILE}
    echo "STATE=${STATE}" >> ${CFILE}
    echo "CITY=${CITY}" >> ${CFILE}
    echo "ORG=${ORG}" >> ${CFILE}
    echo "OU=${OU}" >> ${CFILE}
    # #TODO
    echo "DEFAULT_MAILBOX_SIZE=${DEFAULT_MAILBOX_SIZE}" >> "${CFILE}"
    # DB
    echo "LDAPURI=${LDAP_URI}" >> "${CFILE}"
    echo "LDAPSEARCHBASE=${LDAP_SEARCH_BASE}" >> "${CFILE}"
    echo "LDAPBINDUSER=cn=${LDAP_READONLY_USER_USERNAME},${LDAP_BASE_DN}" >> "${CFILE}"
    echo "LDAPBINDPASSWD=\"${LDAP_READONLY_USER_PASSWORD}\"" >> "${CFILE}"


    # config dump
    if [ "${MDA_DEBUG_INIT}" ] ; then
        echo "Config file dump:"
        cat ${CFILE}
    fi

    # force creation of sive fodler
    mkdir -p /var/lib/dovecot/sieve/
    echo "Sieve folder created!"

    # create the default sieve filter
    FILE=/var/lib/dovecot/sieve/default.sieve
    echo 'require "fileinto";' > ${FILE}
    echo 'if header :contains "X-Spam-Flag" "YES" {' >> ${FILE}
    echo '    fileinto "Junk";' >> ${FILE}
    echo '}' >> ${FILE}
    echo "Sieve default SPAM filter created"

    # fix ownership
    #chown -R vmail:vmail /var/lib/dovecot

    # compile it
    sievec /var/lib/dovecot/sieve/default.sieve
    echo "Sieve compilation done"

    # Run the configuration
    echo "Config starting"
    /configure.sh

    ## dhparms generation
    if [ ! -f /certs/RSA2048.pem ] ; then
        echo "Generation of SAFE dhparam, this may take a time, be patient..."
        openssl dhparam -out /certs/RSA2048.pem -5 2048
        chmod 0644 /certs/RSA2048.pem
        echo "dhparam generated!"
    else
        echo "DHparam already present, skiping generation!"
    fi

    # provision openldap certs
    OPENLDAP=`echo "${POSTFIX_LDAP_URI}" | cut -d "/" -f 3 | cut -d ":" -f 1 `
    echo "Using ${OPENLDAP} as openldap service"

    echo "Get & Install of the ssl cert for the LDAP connections"
    echo | openssl s_client -connect ${OPENLDAP}:636 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/ssl/certs/openldap.crt
    cat /etc/ssl/certs/openldap.crt | head -n 3

    # install the cert into the LDAP client setting
    cat /etc/ldap/ldap.conf | grep -v TLS_CACERT > /tmp/1
    echo "TLS_CACERT /etc/ssl/certs/samba.crt" >> /tmp/1
    cat /tmp/1 > /etc/ldap/ldap.conf
    rm /tmp/1
    
    # debug
    if [ "${MDA_DEBUG_AUTH}" ]; then
        # set auth_verbose & auth_debug to yes
        sed -i s/"^auth_verbose .*$"/"auth_verbose = yes"/g /etc/dovecot/conf.d/10-logging.conf
        sed -i s/"^auth_debug .*$"/"auth_debug = yes"/g /etc/dovecot/conf.d/10-logging.conf

        echo "Auth verbose logging set to yes"
    fi
    if [ "${MTA_DEBUG_AUTH_PASSWORD}" ]; then
        # set auth_verbose_passwords & auth_debug_passwords to yes
        sed -i s/"^auth_verbose_passwords .*$"/"auth_verbose_passwords = yes"/g /etc/dovecot/conf.d/10-logging.conf
        sed -i s/"^auth_debug_passwords .*$"/"auth_debug_passwords = yes"/g /etc/dovecot/conf.d/10-logging.conf

        echo "Auth passwords verbose logging set to yes"
    fi
    if [ "${MTA_DEBUG_MAIL}" ]; then
        # set mail_debug to yes
        sed -i s/"^mail_debug .*$"/"mail_debug = yes"/g /etc/dovecot/conf.d/10-logging.conf

        echo "Mail verbose logging set to yes"
    fi
    if [ "${MTA_DEBUG_SSL}" ]; then
        # set verbose_ssl to yes
        sed -i s/"^verbose_ssl .*$"/"verbose_ssl = yes"/g /etc/dovecot/conf.d/10-logging.conf

        echo "SSL verbose logging set to yes"
    fi

    # create the flag file
    touch /etc/dovecot/configured
    echo "Flag created: container ready!"

    # debug, remove the config file at the end or not if debugging
    if [ -z "${MDA_DEBUG_INIT}" ] ; then
        rm ${CFILE}
    fi
fi

if [ "$1" = 'dovecot' ]; then
    if [ ! -f /certs/mail.crt -o ! -f /certs/mail.key -o ! -f /certs/RSA2048.pem ] ; then
        echo "Ooops! There is some SSL files missing"
        echo "We need a valid 'mail.crt' & 'mail.key' files in the /certs volume!"
        exit 1
    fi

    exec /usr/sbin/dovecot -F < /dev/null
fi

exec "$@"
