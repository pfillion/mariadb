#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [[ "${MOBYCRON_ENABLED}" == "true" || "${MOBYCRON_ENABLED}" == "1" ]]; then
    mobycron &
fi

if [ "$1" = 'mysqld' ]; then
    exec docker-entrypoint.sh "$@"
fi

exec "$@"