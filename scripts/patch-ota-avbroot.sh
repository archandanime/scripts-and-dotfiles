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

export lastest_magisk_release=`curl -si https://github.com/topjohnwu/Magisk/releases/latest | grep "location:" | sed -e 's/location:\ https:\/\/github.com\/topjohnwu\/Magisk\/releases\/tag\///g' | tr -d '\r'`
export current_magisk_release=`basename -s .apk ${MAGISK_FILE} | sed -e 's/Magisk-//g'`


show_syntax() {
	echo "avbroot patcher script for Pixel 4 XL(coral)"
	echo "Syntax: ./patch-ota.sh [magisk|kernelsu]"
	echo
}

patch_with_magisk() {
	echo
	echo -e "[INFO] Patching ${OTA_ZIP},\n\tusing ${MAGISK_FILE},\n\twith pre-init device: ${MAGISK_PREINIT_DEVICE}"
	export PATCHED_OTA_ZIP=${MAGISK_PATCHED_OTA_ZIP}
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
	--output ${PATCHED_OTA_ZIP}

	echo
	[[ "${current_magisk_release}" != "${lastest_magisk_release}" ]] && echo -n "[WARNING] Magisk is outdated" || echo -n "[OK] Magisk is up-to-date"
	echo " (current: ${current_magisk_release}, lastest: ${lastest_magisk_release})"

}

patch_with_kernelsu() {
	echo
	echo -e "Patching ${OTA_ZIP},\nusing ${KERNELSU_BOOT_IMG}"
	PATCHED_OTA_ZIP=${KERNELSU_PATCHED_OTA_ZIP}
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
	--output ${PATCHED_OTA_ZIP}
}


show_syntax
case "${@}" in
	"")
		echo "[INFO] No argument was provided, patching with Magisk as default option"
		patch_with_magisk ;;
	"magisk")
		patch_with_magisk ;;
	"kernelsu")
		patch_with_kernelsu ;;
	*)
		exit 1 ;;
esac
#echo LineageOS build is ${lineageos_build_outdate} days old
[[ ${lineageos_build_outdate} -gt 7 ]] && echo -n "[WARNING] LineageOS build is outdated" || echo -n "[OK] LineageOS build is up-to-date"
echo " (${lineageos_build_outdate} days old)"
echo "[INFO] Output file: ${PATCHED_OTA_ZIP}"
