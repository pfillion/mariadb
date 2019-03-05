#!/bin/bash
set -eo pipefail
shopt -s nullglob

source /usr/local/bin/secret-helper.sh

export_secret_from_env "MYSQL_ROOT_PASSWORD"

if [ ! -d /var/mariadb/backup/ ]
then
    mkdir -p /var/mariadb/backup/
fi

SOCKET="$(mysql -uroot -p${MYSQL_ROOT_PASSWORD} -sse 'SHOW VARIABLES LIKE '\''socket'\'';' | awk '{print $2}')"

mariabackup --backup \
   --user=root \
   --password=${MYSQL_ROOT_PASSWORD} \
   --socket=$SOCKET \
   --stream=xbstream | gzip > /var/mariadb/backup/backup.gz