#!/bin/bash

export CRYPTHEADER="/boot/archroot-cryptheader.img"
export CRYPTHEADER_KEYFILE="/boot/archroot-cryptheader-keyfile.txt"


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Please run as root"
    exit
fi

if ! losetup | grep -q ${CRYPTHEADER}; then
	losetup -f ${CRYPTHEADER}
fi

CRYPTHEADER_LOOP=`losetup | grep ${CRYPTHEADER} | cut -d' ' -f1`
echo "[info] Please paste the contents of ${CRYPTHEADER_KEYFILE} as the following request."
clevis luks bind -d ${CRYPTHEADER_LOOP} tpm2 '{"pcr_bank":"sha256","pcr_ids":"1,7"}'

mkinitcpio -P
