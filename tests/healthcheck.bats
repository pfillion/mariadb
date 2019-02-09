#!/usr/bin/env bats

VERSION=${VERSION:-latest}
CONTAINER_NAME="mariadb-${VERSION}"

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry(){
	local attempts=$1
	shift
	local delay=$1
	shift
	local i

	for ((i=0; i < attempts; i++)); do
		run "$@"
		if [[ "$status" -eq 0 ]]; then
			return 0
		fi
		sleep $delay
	done

	echo "Command \"$@\" failed $attempts times. Output: $output"
	false
}

function is_ready(){
	docker logs ${CONTAINER_NAME} 2>&1 | tr "\n" " " | grep "MySQL init process done.*mysqld: ready for connections"
}

function teardown(){
    docker rm -f ${CONTAINER_NAME}
}

@test "healthcheck" {
    docker run -d --name ${CONTAINER_NAME} -e 'MYSQL_ROOT_PASSWORD=rootpw' -e 'MYSQL_USER=foo' -e 'MYSQL_PASSWORD=bar' pfillion/mariadb:${VERSION}
    retry 30 1 is_ready
    
    # Given invalid user, when check health, then login failed and 1 is returned
    run docker exec -e 'MYSQL_USER=notfoo' ${CONTAINER_NAME} healthcheck
    [ "$status" -eq 1 ]

    # Given valid root password only, when check health, then query is done and 0 is returned
    run docker exec -e 'MYSQL_ROOT_PASSWORD=rootpw' -e 'MYSQL_USER=' -e 'MYSQL_PASSWORD=' ${CONTAINER_NAME} healthcheck
    [ "$status" -eq 0 ]

    # Given valid user and password, when check health, then query is done and 0 is returned
    run docker exec -e 'MYSQL_USER=foo' -e 'MYSQL_PASSWORD=bar' ${CONTAINER_NAME} healthcheck
    [ "$status" -eq 0 ]
}