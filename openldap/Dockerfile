FROM osixia/openldap:latest

LABEL image.app="Openldap, http://github.com/adrianrp1988/openldap"
LABEL image.name="Openldap image baked for maild"
LABEL org.opencontainers.image.description="Openldap container as a backend for Maild"
LABEL org.opencontainers.image.source=https://github.com/adrianrp1988/openldap
LABEL org.opencontainers.image.licenses=GPL-3.0
LABEL maintainer="Adrian Rodriguez <adrianrp1988@gmail.com>"
LABEL last_modified="2026-03-21"

#repoubuntu

ENV DEBIAN_FRONTEND=noninteractive

COPY docker-entrypoint.sh /usr/local/bin
COPY maild-startup.sh maild.ldif /container/service/slapd/assets/config/bootstrap/ldif/custom/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /container/service/slapd/assets/config/bootstrap/ldif/custom/maild-startup.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

