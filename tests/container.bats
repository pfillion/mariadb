#!/usr/bin/env bats

NS=${NS:-pfillion}
IMAGE_NAME=${IMAGE_NAME:-mariadb}
VERSION=${VERSION:-latest}
CONTAINER_NAME="mariadb-${VERSION}"

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

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
    docker run -d --name ${CONTAINER_NAME} -e 'MYSQL_ROOT_PASSWORD=rootpw' -e 'MYSQL_USER=foo' -e 'MYSQL_PASSWORD=bar' ${NS}/${IMAGE_NAME}:${VERSION}
    retry 120 1 is_ready
    
    # Given invalid user, when check health, then login failed and 1 is returned.
    run docker exec -e 'MYSQL_USER=notfoo' ${CONTAINER_NAME} healthcheck
    assert_failure

    # Given valid root password only, when check health, then query is done and 0 is returned.
    run docker exec -e 'MYSQL_ROOT_PASSWORD=rootpw' -e 'MYSQL_USER=' -e 'MYSQL_PASSWORD=' ${CONTAINER_NAME} healthcheck
    assert_success

    # Given valid user and password, when check health, then query is done and 0 is returned.
    run docker exec -e 'MYSQL_USER=foo' -e 'MYSQL_PASSWORD=bar' ${CONTAINER_NAME} healthcheck
    assert_success
}

@test "entrypoint" {
    # Given mysqld command to the entry point, when start container, then only mysqld process is started.
    docker run -d --name ${CONTAINER_NAME} --entrypoint entrypoint.sh -e 'MYSQL_ROOT_PASSWORD=rootpw' ${NS}/${IMAGE_NAME}:${VERSION} mysqld
   	run docker top ${CONTAINER_NAME}
	assert_output -p 'mysqld'
	refute_output -p 'mobycron'

	# Given MOBYCRON_ENABLED=true, when execute the entry point, then mobycron process is started with backup job.
	run docker exec -d -e 'MOBYCRON_ENABLED=true' ${CONTAINER_NAME} entrypoint.sh
	run docker top ${CONTAINER_NAME}
	assert_output -p 'mysqld'
	assert_output -p 'mobycron'

	# Given MOBYCRON_ENABLED=1, when execute the entry point, then mobycron process is started.
	run docker exec -d ${CONTAINER_NAME} pkill mobycron
	run docker top ${CONTAINER_NAME}
	refute_output -p 'mobycron'

	run docker exec -d -e 'MOBYCRON_ENABLED=1' ${CONTAINER_NAME} entrypoint.sh
	run docker top ${CONTAINER_NAME}
	assert_output -p 'mysqld'
	assert_output -p 'mobycron'

	# Given any command, when execute the entry point, then the process of the command is started.
	run docker exec -d ${CONTAINER_NAME} entrypoint.sh sleep 10
	run docker top ${CONTAINER_NAME}
	assert_output -p 'sleep 10'
}

@test "backup" {
    docker run -d --name ${CONTAINER_NAME} -e 'MYSQL_ROOT_PASSWORD=rootpw' ${NS}/${IMAGE_NAME}:${VERSION}
    retry 120 1 is_ready

    # Given a root password, when backing up the server, then compressed backup file is created in a new folder
    run docker exec ${CONTAINER_NAME} backup.sh
	assert_success
	run docker exec ${CONTAINER_NAME} gunzip -tv /var/mariadb/backup/backup.gz
	assert_output -p 'OK'

	# Given backup folder already exist, when backing up the server, then compressed backup file is created in the folder
    run docker exec ${CONTAINER_NAME} bash -c 'rm /var/mariadb/backup/*'
	assert_success
    run docker exec ${CONTAINER_NAME} backup.sh
	assert_success
	run docker exec ${CONTAINER_NAME} gunzip -tv /var/mariadb/backup/backup.gz
	assert_output -p 'OK'

	# Given backup file already exist, when backing up the server, then backup file is overridden
	run docker exec ${CONTAINER_NAME} bash -c 'rm /var/mariadb/backup/*'
	run docker exec ${CONTAINER_NAME} touch /var/mariadb/backup/backup.gz
    run docker exec ${CONTAINER_NAME} backup.sh
	assert_success
	run docker exec ${CONTAINER_NAME} gunzip -tv /var/mariadb/backup/backup.gz
	assert_output -p 'OK'
}