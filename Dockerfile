ARG VERSION
FROM mariadb:$VERSION

# Build-time metadata as defined at http://label-schema.org
ARG VERSION
ARG BUILD_DATE
ARG VCS_REF
LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="mariadb" \
    org.label-schema.description="These are docker images for MariaDB." \
    org.label-schema.url="https://hub.docker.com/r/pfillion/mariadb" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/pfillion/mariadb" \
    org.label-schema.vendor="pfillion" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

ADD usr /usr