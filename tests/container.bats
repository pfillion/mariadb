#!/usr/bin/env bats

NS=${NS:-pfillion}
IMAGE_NAME=${IMAGE_NAME:-mariadb}
VERSION=${VERSION:-latest}
CONTAINER_NAME="mariadb-${VERSION}"

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

function teardown(){
    docker rm -f ${CONTAINER_NAME}
}

@test "healthcheck" {
    docker run -d --name ${CONTAINER_NAME} -e 'MARIADB_ROOT_PASSWORD=rootpw' -e 'MARIADB_USER=foo' -e 'MARIADB_PASSWORD=bar' -e 'MARIADB_INITDB_SKIP_TZINFO=1' ${NS}/${IMAGE_NAME}:${VERSION}
	sleep 30
    
    # Given invalid user, when check health, then login failed and 1 is returned.
    run docker exec -e 'MARIADB_USER=notfoo' ${CONTAINER_NAME} healthcheck
    assert_failure

    # Given valid root password only, when check health, then query is done and 0 is returned.
    run docker exec -e 'MARIADB_ROOT_PASSWORD=rootpw' -e 'MARIADB_USER=' -e 'MARIADB_PASSWORD=' ${CONTAINER_NAME} healthcheck
    assert_success

    # Given valid user and password, when check health, then query is done and 0 is returned.
    run docker exec -e 'MARIADB_USER=foo' -e 'MARIADB_PASSWORD=bar' ${CONTAINER_NAME} healthcheck
    assert_success
}

@test "backup" {
    docker run -d --name ${CONTAINER_NAME} -e 'MARIADB_ROOT_PASSWORD=rootpw' -e 'MARIADB_INITDB_SKIP_TZINFO=1' ${NS}/${IMAGE_NAME}:${VERSION}
    sleep 30

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