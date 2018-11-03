ARG BASE=alpine
FROM $BASE

ARG arch=arm
ENV ARCH=$arch

COPY qemu/qemu-$ARCH-static* /usr/bin/

#install required libraries & clean up to keep thin layer
# libcap-dev    -> drop capabilities
# samba-dev     -> cifsacl and cifs.idmap
# keyutils-dev  -> cifs.idmap cifs.upcall cifscreds and cifscreds PAM module <- it does not work -> disable
# krb5 krb5-dev -> cifs.upcall <- it does not work -> disable
ENV PKGS="alpine-sdk libtool automake autoconf libcap-dev samba-dev"
RUN apk add --no-cache \
      $PKGS \
#download & make jq from source
    && echo "Downloading jq" \
    && (cd /tmp; curl -Lo jq.tar.gz https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz) \
    && (cd /tmp; mkdir jq; tar -xf jq.tar.gz -C jq --strip-components=1; rm jq.tar.gz) \
    && echo "Building jq" \
    && (cd /tmp/jq/; autoreconf -i && ./configure --enable-all-static && make -j) \
    && ls -l /tmp/jq \
    && cp /tmp/jq/jq /usr/local/bin/ \
#download & make mount.cifs from source
    && echo "Downloading cifs" \
    && (cd /tmp; curl -Lo cifs-utils.tar.bz2 http://ftp.samba.org/pub/linux-cifs/cifs-utils/cifs-utils-6.8.tar.bz2) \
    && (cd /tmp; mkdir cifs-utils; tar -xf cifs-utils.tar.bz2 -C cifs-utils --strip-components=1; rm cifs-utils.tar.bz2) \
    && echo "Building cifs" \
    && (cd /tmp/cifs-utils/; ./configure LDFLAGS="-static" && make -j) \
    && ls -l /tmp/cifs-utils/mount.cifs \
    && cp /tmp/cifs-utils/mount.cifs /usr/local/bin/ \
#Clean up
    && apk del $PKGS \
    && rm -rf /var/cache/apk/* /tmp/*


WORKDIR /usr/local/bin
COPY cifs.sh run.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run.sh"]
