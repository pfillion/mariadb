#!/bin/bash
set -eo pipefail
shopt -s nullglob

source /usr/local/bin/secret-helper.sh

export_secret_from_env "MARIADB_ROOT_PASSWORD"

if [ ! -d /var/mariadb/backup/ ]
then
    mkdir -p /var/mariadb/backup/
fi

SOCKET="$(mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -sse 'SHOW VARIABLES LIKE '\''socket'\'';' | awk '{print $2}')"

mariabackup --backup \
   --user=root \
   --password=${MARIADB_ROOT_PASSWORD} \
   --socket=$SOCKET \
   --stream=xbstream | gzip > /var/mariadb/backup/backup.gz