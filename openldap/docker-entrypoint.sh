#!/bin/bash
set -e

/container/service/slapd/assets/config/bootstrap/ldif/custom/maild-startup.sh

sleep 2

# Lanzar el entrypoint original en background
/container/tool/run "$@" &
pid=$!

wait $pid
