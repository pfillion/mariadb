#!/bin/bash
set -euo pipefail
shopt -s nullglob

source /usr/local/bin/secret-helper.sh
export_secret_from_env "MARIADB_ROOT_PASSWORD"

BACKUP_DIR="/var/mariadb/backup"
BACKUP_FILE="${BACKUP_DIR}/backup.gz"
TMP_FILE="${BACKUP_DIR}/backup.gz.tmp"

mkdir -p "${BACKUP_DIR}"

# Get Socket by query
SOCKET="$(mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -Nse 'SELECT @@socket;')"

# Backup, write into tmp file before
mariadb-backup --backup \
  --user=root \
  --password="${MARIADB_ROOT_PASSWORD}" \
  --socket="${SOCKET}" \
  --stream=xbstream \
  | gzip -c > "${TMP_FILE}"

mv -f "${TMP_FILE}" "${BACKUP_FILE}"

# Flush binary logs after backup
mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "FLUSH BINARY LOGS;"