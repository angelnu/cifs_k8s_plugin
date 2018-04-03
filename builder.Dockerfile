FROM alpine

#install required libraries & clean up to keep thin layer
RUN apk add --no-cache \
      alpine-sdk automake autoconf libtool \
      cifs-utils

#download & make mount.cifs from source
RUN mkdir -p /tmp/bin/ && \
    cp /sbin/mount.cifs /tmp/bin/


#download & make jq from source
RUN (cd /tmp; curl -Lo jq.tar.gz https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz) \
    && (cd /tmp; mkdir jq; tar -xf jq.tar.gz -C jq --strip-components=1; rm jq.tar.gz) \
    && (cd /tmp/jq/; autoreconf -i && ./configure --enable-all-static && make -j) \
    && mkdir -p /tmp/bin/ \
    && ls /tmp/jq \
    && cp /tmp/jq/jq /tmp/bin/

#download & make mount.cifs from source
RUN (cd /tmp; curl -Lo cifs-utils.tar.bz2 http://ftp.samba.org/pub/linux-cifs/cifs-utils/cifs-utils-6.5.tar.bz2) \
    && (cd /tmp; mkdir cifs-utils; tar -xf cifs-utils.tar.bz2 -C cifs-utils --strip-components=1; rm cifs-utils.tar.bz2) \
    && (cd /tmp/cifs-utils/; ./configure LDFLAGS="-static" && make -j) \
    && mkdir -p /tmp/bin/ \
    && cp /tmp/cifs-utils/mount.cifs /tmp/bin/

#prepare WORKDIR
COPY run.Dockerfile /tmp/bin/Dockerfile
COPY cifs.sh /tmp/bin/cifs.sh
COPY run.sh /tmp/bin/run.sh
WORKDIR /tmp/bin/

# Export the WORKDIR as a tar stream
CMD tar -cf - .
