#!/bin/bash

#
# Generate archroot-cryptheader.img, archroot-cryptheader-keyfile.txt
#
#


export HEADER_SOURCE="/boot/my-cryptkeys.d/disk/archroot-header.img"
export HEADER_COPY="/boot/archroot-header.img"
export CRYPTHEADER="/boot/archroot-cryptheader.img"
export CRYPTHEADER_KEYFILE="/boot/archroot-cryptheader-keyfile.txt"
export CRYPTHEADER_KEYFILE_EXTRA="/boot/archroot-cryptheader-keyfile-extra.txt"
export CRYPTHEADER_MAPPER="cryptheader_generate"

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Please run as root"
    exit
fi

if ! cmp --silent ${HEADER_COPY} ${HEADER_SOURCE}; then
	echo "[info] Copy of LUKS header file does not match, making a new copy"
	cp ${HEADER_SOURCE} ${HEADER_COPY} && echo "[OK] Copy succeeded" || { echo "[ERR] Copy failed"; exit 1; }
fi


read -p "This will delete all old encryptheader-related files. Are you sure to continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


echo "[info] Creating 32M empty file for encrypted header"
dd if=/dev/zero of=${CRYPTHEADER} count=33554432 bs=32M count=1 status=progress && echo "[OK] Creation succeeded" || { echo "[ERR] Creation failed"; exit 1; }

echo "[info] Generate keyfile for cryptheader LUKS container"
tr -dc 'a-f0-9' < /dev/urandom | head -c64 > ${CRYPTHEADER_KEYFILE} && echo "[OK] Generation succeeded" || { echo "[ERR] Generation failed"; exit 1; }
chmod 600 ${CRYPTHEADER_KEYFILE}

echo "[info] Generating an extra keyfile for cryptheader LUKS container"
tr -dc 'a-f0-9' < /dev/urandom | head -c32 > ${CRYPTHEADER_KEYFILE_EXTRA} && echo "[OK] Generation succeeded" || { echo "[ERR] Generation failed"; exit 1; }
chmod 600 ${CRYPTHEADER_KEYFILE_EXTRA}

echo "[info] Creating cryptheader LUKS container"
cryptsetup -q luksFormat ${CRYPTHEADER} --key-file ${CRYPTHEADER_KEYFILE} && echo "[OK] Creation succeeded" || { echo "[ERR] Creation failed"; exit 1; }

echo "[info] Adding an extra keyfile for cryptheader LUKS container"
cat ${CRYPTHEADER_KEYFILE} | cryptsetup luksAddKey ${CRYPTHEADER} ${CRYPTHEADER_KEYFILE_EXTRA} && echo "[OK] Adding succeeded" || { echo "[ERR] Adding failed"; exit 1; }

echo "[info] Mapping cryptheader LUKS container"
cryptsetup open ${CRYPTHEADER} --key-file ${CRYPTHEADER_KEYFILE} ${CRYPTHEADER_MAPPER} && echo "[OK] Mappping succeeded" || { echo "[ERR] Mapping failed"; exit 1; }

echo "[info] Writing header file to decrypted cryptheader LUKS container"
dd if=${HEADER_COPY} of=/dev/mapper/${CRYPTHEADER_MAPPER} status=progress && echo "[OK] Writing succeeded" || { echo "[ERR] Writing failed"; exit 1; }

echo "[info] Closing cryptheader LUKS container"
cryptsetup close ${CRYPTHEADER_MAPPER}

echo "[info] Detaching ${CRYPTHEADER}"
loop_cryptheader=`losetup -O NAME,BACK-FILE |grep ${CRYPTHEADER} | cut -d ' ' -f2`
losetup -d ${loop_cryptheader} && echo "[OK] Detaching succeeded" || { echo "[ERR] Detaching failed"; exit 1; }
