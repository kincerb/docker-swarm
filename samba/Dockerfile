FROM ubuntu:18.04
RUN apt update && apt install -y samba && \
    useradd kincerb && mkdir /samba && \
    chown kincerb:kincerb /samba

HEALTHCHECK CMD curl --fail http://localhost:137 || exit 1

COPY entrypoint.sh /
RUN chmod 750 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 137
EXPOSE 138
EXPOSE 139
EXPOSE 445
VOLUME /samba

