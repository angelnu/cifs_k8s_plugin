#!/bin/bash

# Credits: taken and fixed from
# http://stackoverflow.com/questions/38120916/kubernetes-flexvolume-plugin-for-cifs
# https://github.com/phlbrz/cifs_k8s_plugin

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Notes:
#  - Please install "jq" package before using this driver.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

JQ="$DIR/jq"
MOUNT_CIFS="$DIR/mount.cifs"

usage() {
	err "Invalid usage. Usage: "
	err "\t$0 init"
	err "\t$0 attach <json params>"
	err "\t$0 detach <mount device>"
	err "\t$0 mount <mount dir> <json params>" # ( $2 was  <mount device> , now it's removed )
	err "\t$0 unmount <mount dir>"
	exit 1
}

err() {
	echo -e $* 1>&2
}

log() {
	echo -e $* >&1
}

ismounted() {
	MOUNT=`findmnt -n ${MNTPATH} 2>/dev/null | cut -d' ' -f1`
	[ "${MOUNT}" == "${MNTPATH}" ]
}

domount() {
        MNTPATH="$1"
	#DMDEV="$2" ## $2 arg is deprecated ( no longer provided to flexvolume )
	      VOLUME_SRC=$(echo "$2"|"$JQ" -r '.source') # this is a json string ie : {"kubernetes.io/fsType":"","kubernetes.io/readwrite":"ro","source":"//xxxx.xxx.com/backup"}
        READ_MODE=$(echo "$2"|"$JQ" -r '.["kubernetes.io/readwrite"]')
        MOUNT_OPTIONS=$(echo "$2"|"$JQ" -r '.mountOptions // empty')

        USERNAME=$(echo "$2"|"$JQ" -r '.["kubernetes.io/secret/username"] // empty'|base64 -d)
        PASSWORD=$(echo "$2"|"$JQ" -r '.["kubernetes.io/secret/password"] // empty'|base64 -d)

        ALL_OPTIONS="user=${USERNAME},pass=${PASSWORD},${READ_MODE}"

        if [ -n "$MOUNT_OPTIONS" ]; then
            ALL_OPTIONS="${ALL_OPTIONS},${MOUNT_OPTIONS}"
        fi

        if ismounted ; then
		log '{ "status": "Success", "message": "" }'
	        exit 0
        fi

        mkdir -p ${MNTPATH} &> /dev/null

        "$MOUNT_CIFS" -o "${ALL_OPTIONS}" "${VOLUME_SRC}" "${MNTPATH}" &> /dev/null

        #MOUNTCMD=$MOUNT_CIFS' -o '${ALL_OPTIONS}' '${VOLUME_SRC}' '${MNTPATH}
        if [ $? -ne 0 ]; then
                #err '{ "status": "Failure", "message": "Failed to mount at '${MNTPATH}' , user: '${USERNAME}' , '${VOLUME_SRC}' , cmd ='${MOUNTCMD}', READ_MODE='${READ_MODE}' "}'
                err '{ "status": "Failure", "message": "Failed to mount at '${MNTPATH}'" }'
                exit 1
        fi
	log '{ "status": "Success", "message": "" }'
        exit 0
}

unmount() {
        MNTPATH="$1"
        if ! ismounted ; then
		log '{ "status": "Success", "message": "" }'
  		exit 0
        fi

        umount -l "${MNTPATH}" &> /dev/null
        if [ $? -ne 0 ]; then
                err '{ "status": "Failed", "message": "Failed to unmount volume at '${MNTPATH}'" }'
                exit 1
        fi
        rmdir "${MNTPATH}" &> /dev/null
	log '{ "status": "Success", "message": "" }'
        exit 0
}

op=$1

if [ "$op" = "init" ]; then
	log '{ "status": "Success", "capabilities": { "attach": false, "selinuxRelabel": false } }'
        exit 0
fi

if [ $# -lt 2 ]; then
        usage
fi

shift

case "$op" in
        mount)
                domount $*
                ;;
	unmount)
		unmount $*
		;;
	*)
		log '{ "status": "Not supported" }'
 		exit 0

esac
