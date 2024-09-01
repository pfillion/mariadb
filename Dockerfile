ARG CURRENT_VERSION_MICRO

FROM pfillion/mobycron:latest as mobycron
FROM mariadb:$CURRENT_VERSION_MICRO

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
ARG DATE
ARG CURRENT_VERSION_MICRO
ARG COMMIT
ARG AUTHOR

LABEL \
    org.opencontainers.image.created=$DATE \
    org.opencontainers.image.url="https://hub.docker.com/r/pfillion/mariadb" \
    org.opencontainers.image.source="https://github.com/pfillion/mariadb" \
    org.opencontainers.image.version=$CURRENT_VERSION_MICRO \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor="pfillion" \
    org.opencontainers.image.title="mariadb" \
    org.opencontainers.image.description="These are docker images for MariaDB." \
    org.opencontainers.image.authors=$AUTHOR \
    org.opencontainers.image.licenses="MIT"

COPY rootfs /
COPY --from=mobycron /usr/bin/mobycron /usr/bin

VOLUME [ "/var/mariadb/backup/" ]

ENTRYPOINT [ "entrypoint.sh" ]

CMD ["mariadbd"]