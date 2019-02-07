#!/usr/bin/env bats

VERSION=${VERSION:-latest}

function teardown(){
    docker stop mariadb-container
}

@test "Given empty root password, when check health, then 1 is returned" {
    docker run -d --rm --name mariadb-container -e 'MYSQL_ALLOW_EMPTY_PASSWORD=1' pfillion/mariadb:${VERSION}
    sleep 20

    run docker exec healthcheck

    [ "$status" -eq 1 ]
}

@test "Given any root password, when check health, then 0 is returned" {
    docker run -d --rm --name mariadb-container -e 'MYSQL_ROOT_PASSWORD=foo' pfillion/mariadb:${VERSION}
    sleep 20
    
    docker logs mariadb-container

    run docker exec mariadb-container healthcheck

    [ "$status" -eq 0 ]
}

@test "Given any user and password, when check health, then 0 is returned" {
    docker run -d --rm --name mariadb-container -e 'MYSQL_USER=foo' -e 'MYSQL_PASSWORD=bar' -e 'MYSQL_RANDOM_ROOT_PASSWORD=1' pfillion/mariadb:${VERSION}
    sleep 20

    run docker exec mariadb-container healthcheck

    [ "$status" -eq 0 ]
}