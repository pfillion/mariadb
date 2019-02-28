#!/bin/bash
set -eo pipefail
shopt -s nullglob

source /usr/local/bin/secret-helper.sh

export_secret_from_env "MYSQL_ROOT_PASSWORD"

if [ ! -d /var/mariadb/backup/ ]
then
    mkdir -p /var/mariadb/backup/
fi

mariabackup --backup \
   --user=root \
   --password=${MYSQL_ROOT_PASSWORD} \
   --stream=xbstream | gzip > /var/mariadb/backup/backup.gz