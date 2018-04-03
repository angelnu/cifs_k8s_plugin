FROM alpine:latest

COPY run.sh /tmp/bin/run.sh
COPY mount.cifs /tmp/bin/mount.cifs
COPY cifs.sh /tmp/bin/cifs.sh
COPY jq /tmp/bin/jq
WORKDIR /tmp/bin/

ENTRYPOINT ["/tmp/bin/run.sh"]
