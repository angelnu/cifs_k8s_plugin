#!/bin/sh

TARGET=${1:-/tmp/local/bin}
echo "Deploy plugin to $TARGET"
rm -rf "$TARGET"/*
cp jq "$TARGET/jq"
cp mount.cifs "$TARGET/mount.cifs"
cp cifs.sh "$TARGET/cifs"

while true; do
	sleep 3600;
done
