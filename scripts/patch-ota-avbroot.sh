#!/bin/bash
#
# avbroot OTA patcher script for Pixel 4 XL(coral)
#


export BASEDIR=~/avbroot-Pixel4XL/

export OTA_ZIP=${BASEDIR}/input/lineage-20.0-20230709-nightly-coral-signed.zip
export MAGISK_FILE=${BASEDIR}/input/Magisk-v26.1.apk
export MAGISK_PREINIT_DEVICE=userdata
export KERNELSU_BOOT_IMG=${BASEDIR}/input/pixel4xl_android13_4.14.276_v061.img

export PASSPHRASE_AVB=""
export PASSPHRASE_OTA=""
export AVB_KEYFILE=${BASEDIR}/signing-keys/avb.key
export OTA_KEYFILE=${BASEDIR}/signing-keys/ota.key
export OTA_CRT=${BASEDIR}/signing-keys/ota.crt
export MAGISK_PATCHED_OTA_ZIP=`echo ${BASEDIR}/output/$(basename -s .zip ${OTA_ZIP})_$(basename -s .apk ${MAGISK_FILE})_PATCHED.zip`
export KERNELSU_PATCHED_OTA_ZIP=`echo ${BASEDIR}/output/$(basename -s .zip ${OTA_ZIP})_$(basename -s .img ${KERNELSU_BOOT_IMG})_PATCHED.zip`

export lineageos_build_date=`basename ${OTA_ZIP} | cut -d '-' -f3`
export today_date=`date +%Y%m%d`
export lineageos_build_outdate=$(( ${today_date} - ${lineageos_build_date} ))
export lastest_magisk_release=`curl -L -s https://github.com/topjohnwu/Magisk/releases/latest | grep '<title>' | sed -e 's/<[^>]*>//g'`


show_syntax() {
	echo "avbroot patcher script for Pixel 4 XL(coral)"
	echo "Syntax: ./patch-ota.sh [magisk|kernelsu]"
	echo
}

patch_with_magisk() {
	echo
	echo -e "Patching ${OTA_ZIP},\n\tusing ${MAGISK_FILE},\n\twith pre-init device: ${MAGISK_PREINIT_DEVICE}"
	python avbroot/avbroot.py patch \
	--input ${OTA_ZIP} \
	--privkey-avb ${AVB_KEYFILE} \
	--privkey-ota ${OTA_KEYFILE} \
	--cert-ota ${OTA_CRT} \
	--magisk ${MAGISK_FILE} \
	--magisk-preinit-device ${MAGISK_PREINIT_DEVICE} \
	--clear-vbmeta-flags \
	--passphrase-avb-env-var PASSPHRASE_AVB \
	--passphrase-ota-env-var PASSPHRASE_OTA \
	--output ${MAGISK_PATCHED_OTA_ZIP}

	echo
	echo "Output file: ${MAGISK_PATCHED_OTA_ZIP}"
	echo "Lastest Magisk: ${lastest_magisk_release}"

}

patch_with_kernelsu() {
	echo
	echo -e "Patching ${OTA_ZIP},\nusing ${KERNELSU_BOOT_IMG}"
	python avbroot/avbroot.py patch \
	--input ${OTA_ZIP} \
	--privkey-avb ${AVB_KEYFILE} \
	--privkey-ota ${OTA_KEYFILE} \
	--cert-ota ${OTA_CRT} \
	--prepatched ${KERNELSU_BOOT_IMG} \
	--boot-partition @gki_kernel \
	--ignore-prepatched-compat \
	--clear-vbmeta-flags \
	--passphrase-avb-env-var PASSPHRASE_AVB \
	--passphrase-ota-env-var PASSPHRASE_OTA \
	--output ${KERNELSU_PATCHED_OTA_ZIP}
}


show_syntax
case "${@}" in
	"")
		echo "No argument was provided, patching with Magisk as default option"
		patch_with_magisk ;;
	"magisk")
		patch_with_magisk ;;
	"kernelsu")
		patch_with_kernelsu ;;
	*)
		exit 1 ;;
esac
echo LineageOS build is ${lineageos_build_outdate} days outdated
