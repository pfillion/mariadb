#!/usr/bin/env bash
set -eo pipefail
shopt -s nullglob

source /usr/bin/secret-helper.sh

export_secret_from_env "MARIADB_ROOT_PASSWORD"
export_secret_from_env "MARIADB_USERNAME"
export_secret_from_env "MARIADB_PASSWORD"

/usr/bin/healthcheck
exit $?