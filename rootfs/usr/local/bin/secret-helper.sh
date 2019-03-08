#!/bin/bash
set -eo pipefail
shopt -s nullglob

#######################################
# Get secret in file from the environnement variable.
# Exemple:
# The container read the password in this env: ROOT_PASSWORD
# The secret file is must be creted with '_FILE' suffix: ROOT_PASSWORD_FILE
# Call get_secret_from_env 'ROOT_PASSWORD' and it will read secret file stored in ROOT_PASSWORD_FILE.
#
# This is for supporting docker secret feature.
#
# Arguments:
#   1, Any existing environnement variable without suffix '_FILE'
# 	2, Any default value if no environnement variable exist
# Returns:
#   Content of the file specified in the environnement variable suffiex by '_FILE'
#######################################
get_secret_from_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	val="$def"
	if [ "${!fileVar:-}" ]; then
		if [ -e "${!fileVar}" ]; then
			val="$(<"${!fileVar}")"
		else
			echo "The file '${!fileVar}' in environnement variable '$fileVar' not exist."
			exit 1
		fi
	elif [ "${!var:-}" ]; then
		val="${!var}"
	fi
	echo $val
}

#######################################
# Export secret in file to environnement variable.
#
# The secret file path must be in environnement variable with suffix '_FILE'
# The secret value from file is exported into environnement variable received in arguments
#
# This is for supporting docker secret feature.
#
# Arguments:
#   1, Any environnement variable without suffix '_FILE'
# 	2, Any default value if no environnement variable exist
# Returns:
#  	0 or 1 with error
#######################################
export_secret_from_env() {
	result=$(get_secret_from_env "$@")
	if [ $? == 0 ]; then
		export "$1"="$result"
	else
		echo "$result"
		exit 1
	fi
}
