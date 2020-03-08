# MariaDB

[![Build Status](https://drone.pfillion.com/api/badges/pfillion/mariadb/status.svg?branch=master)](https://drone.pfillion.com/pfillion/mariadb)
[![microbadger image](https://images.microbadger.com/badges/image/pfillion/mariadb.svg)](https://microbadger.com/images/pfillion/mariadb "Get your own image badge on microbadger.com")
[![microbadger image](https://images.microbadger.com/badges/version/pfillion/mariadb.svg)](https://microbadger.com/images/pfillion/mariadb "Get your own version badge on microbadger.com")
[![microbadger image](https://images.microbadger.com/badges/commit/pfillion/mariadb.svg)](https://microbadger.com/images/pfillion/mariadb "Get your own commit badge on microbadger.com")

TODO:
* Supporter le FULL RESTORE au démarrage du container
* Un mode qui permet de tester des backups via mobycron par dockerjob

These are docker images for [MariaDB](https://mariadb.org) database. Mainly, it's to manage [healthcheck](https://docs.docker.com/engine/reference/builder/#healthcheck) with credential specified by **secrets**.

The base image is from official [MariaDB](https://hub.docker.com/_/mariadb).

## Versions

* [latest](https://github.com/pfillion/mariadb/tree/master) available as ```pfillion/mariadb:latest``` at [Docker Hub](https://hub.docker.com/r/pfillion/mariadb/)
* [10.3](https://github.com/pfillion/mariadb/tree/master) available as ```pfillion/mariadb:10.3``` at [Docker Hub](https://hub.docker.com/r/pfillion/mariadb/)
* [10.1](https://github.com/pfillion/mariadb/tree/master) available as ```pfillion/mariadb:10.1``` at [Docker Hub](https://hub.docker.com/r/pfillion/mariadb/)

## Volumes

* /var/lib/mysql
* /var/mariadb/backup

## Ports

* 3306

## Using a custom MySQL configuration file

The MariaDB startup configuration is specified in the file `/etc/mysql/my.cnf`, and that file in turn includes any files found in the `/etc/mysql/conf.d` directory that end with `.cnf`. Settings in files in this directory will augment and/or override settings in `/etc/mysql/my.cnf`. If you want to use a customized MySQL configuration, you can create your alternative configuration file in a directory on the host machine and then mount that directory location as `/etc/mysql/conf.d` inside the `mariadb` container.

If `/my/custom/config-file.cnf` is the path and name of your custom configuration file, you can start your `mariadb` container like this (note that only the directory path of the custom config file is used in this command):

```console
$ docker run --name some-mariadb -v /my/custom:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mariadb:tag
```

This will start a new container `some-mariadb` where the MariaDB instance uses the combined startup settings from `/etc/mysql/my.cnf` and `/etc/mysql/conf.d/config-file.cnf`, with settings from the latter taking precedence.

## Environment Variables

When you start the `mariadb` image, you can adjust the configuration of the MariaDB instance by passing one or more environment variables on the `docker run` command line. Do note that none of the variables below will have any effect if you start the container with a data directory that already contains a database: any pre-existing database will always be left untouched on container startup.

### `MYSQL_ROOT_PASSWORD`

This variable is mandatory and specifies the password that will be set for the MariaDB `root` superuser account. In the above example, it was set to `my-secret-pw`.

### `MYSQL_DATABASE`

This variable is optional and allows you to specify the name of a database to be created on image startup. If a user/password was supplied (see below) then that user will be granted superuser access ([corresponding to `GRANT ALL`](http://dev.mysql.com/doc/en/adding-users.html)) to this database.

### `MYSQL_USER`, `MYSQL_PASSWORD`

These variables are optional, used in conjunction to create a new user and to set that user's password. This user will be granted superuser permissions (see above) for the database specified by the `MYSQL_DATABASE` variable. Both variables are required for a user to be created.

Do note that there is no need to use this mechanism to create the root superuser, that user gets created by default with the password specified by the `MYSQL_ROOT_PASSWORD` variable.

### `MYSQL_ALLOW_EMPTY_PASSWORD`

This is an optional variable. Set to `yes` to allow the container to be started with a blank password for the root user. *NOTE*: Setting this variable to `yes` is not recommended unless you really know what you are doing, since this will leave your MariaDB instance completely unprotected, allowing anyone to gain complete superuser access.

### `MYSQL_RANDOM_ROOT_PASSWORD`

This is an optional variable. Set to `yes` to generate a random initial password for the root user (using `pwgen`). The generated root password will be printed to stdout (`GENERATED ROOT PASSWORD: .....`).

### `MOBYCRON_ENABLED`

This is an optional variable. Set to `true` or `1` to enable mobycron deamon. The configuration is specified in the file `/configs/config.json`. By default, this configuration includes a daily backup of the server. The compressed backup file is created in the volume `/var/mariadb/backup`.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -d mariadb:tag
```

Currently, this is only supported for `MYSQL_ROOT_PASSWORD`, `MYSQL_ROOT_HOST`, `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD`.

## Docker Healthcheck

This container provides a script that instructs Docker how to check if the mariadb server still working. For example:

```yaml
healthcheck:
    test: ["CMD", "/usr/local/bin/healthcheck"]
    interval: 30s
    timeout: 30s
    retries: 5
```

## Authors

* [pfillion](https://github.com/pfillion)

## License

MIT