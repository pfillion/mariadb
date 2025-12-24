ARG CURRENT_VERSION_MICRO=latest

FROM pfillion/mobycron:latest AS mobycron
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
    
RUN apt-get update && \
    apt-get install -y \
        supervisor && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY --chmod=0755 rootfs /
COPY --chmod=0755 --from=mobycron /usr/bin/mobycron /usr/bin

VOLUME [ "/var/mariadb/backup/" ]

CMD ["supervisord"]