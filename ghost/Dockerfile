FROM ghost:latest

COPY docker-entrypoint.sh /usr/local/bin

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 755 /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK CMD curl --fail http://localhost:2368 || exit 1
