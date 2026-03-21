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

ADD configure.sh configure.ldif.template /
RUN chmod +x /*.sh
RUN ./configure.sh
RUN rm /configure.sh /configure.ldif.template

