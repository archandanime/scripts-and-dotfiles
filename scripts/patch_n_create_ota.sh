#!/bin/bash
#
# Patch OTA with KernelSU patched boot image with avbroot then generate Custota files for Custota OTA server
#
# Required directories/files:
# - Custota/custotatool - Download from https://github.com/chenxiaolong/Custota/releases, then extract the binary
# - avbroot/ - Clone from https://github.com/chenxiaolong/avbroot
# - input/ - Put OTA zip and KernelSU patched boot image here
# - output/ - Where required files for Custota OTA server to run are generated by this script
# - signing-keys/ - contains AVB key, OTA certificate, OTA key
#

export BASEDIR="/storage/"
export DEVICE_CODENAME="lynx"

export DEVICE_DIR="/storage/${DEVICE_CODENAME}"
export AVB_KEYFILE="${DEVICE_DIR}/signing-keys/lynx_SqK_avb.key"
export OTA_KEYFILE="${DEVICE_DIR}/signing-keys/lynx_SqK_ota.key"
export OTA_CRT="${DEVICE_DIR}/signing-keys/lynx_SqK_ota.crt"

export AVBROOT_DIR="${DEVICE_DIR}/avbroot"
export CUSTOTA_DIR="${DEVICE_DIR}/Custota"
export PASSPHRASE_AVB=""
export PASSPHRASE_OTA=""


show_syntax() {
	echo "./$(basename "$0") <OTA zip> <KernelSU patched GKI>"
	exit 1
}

OTA_ZIP="$1"
KERNELSU_BOOT_IMG="$2"

[ ! -f "${OTA_ZIP}" ] && { echo "OTA zip doesn't exist"; show_syntax; }
[ ! -f "${KERNELSU_BOOT_IMG}" ] && { echo "KernelSU patched GKI doesn't exist"; show_syntax; }

KERNELSU_PATCHED_OTA_ZIP_NAME=`echo $(basename -s .zip ${OTA_ZIP})_$(basename -s .img ${KERNELSU_BOOT_IMG})_PATCHED.zip`
mkdir -p ${DEVICE_DIR}/output


##### Patch OTA with KernelSU patched boot image #####
patch_with_KernelSU() {
echo -e "[info] Patching OTA zip: ${OTA_ZIP} using KernelSU patched boot image: ${KERNELSU_BOOT_IMG}"
python ${AVBROOT_DIR}/avbroot.py patch \
	--input ${OTA_ZIP} \
	--privkey-avb ${AVB_KEYFILE} \
	--privkey-ota ${OTA_KEYFILE} \
	--cert-ota ${OTA_CRT} \
	--prepatched ${KERNELSU_BOOT_IMG} \
	--boot-partition @gki_kernel \
	--ignore-prepatched-compat --ignore-prepatched-compat\
	--clear-vbmeta-flags \
	--passphrase-avb-env-var PASSPHRASE_AVB \
	--passphrase-ota-env-var PASSPHRASE_OTA \
	--output output/${KERNELSU_PATCHED_OTA_ZIP_NAME}
}


##### Extract boot images to be flashed by fastboot #####
extract_pre_installation() {
echo "[info] Extracting boot images to be flashed by fastboot"
python ${AVBROOT_DIR}/avbroot.py \
	extract \
	--input output/${KERNELSU_PATCHED_OTA_ZIP_NAME} \
	--directory ${DEVICE_DIR}/output
}


##### Generate Custota files for Custota OTA server #####
generate_custota_files() {
echo "[info] Generating Custota files for Custota OTA server"
chmod +x ${CUSTOTA_DIR}/custota-tool
${CUSTOTA_DIR}/custota-tool \
	gen-csig \
	--input output/${KERNELSU_PATCHED_OTA_ZIP_NAME} \
	--key ${DEVICE_DIR}/signing-keys/lynx_SqK_ota.key \
	--cert ${DEVICE_DIR}/signing-keys/lynx_SqK_ota.crt \
	--passphrase-env-var PASSPHRASE_OTA

${CUSTOTA_DIR}/custota-tool \
	gen-update-info \
	--file ${DEVICE_DIR}/output/${DEVICE_CODENAME}.json \
	--location output/${KERNELSU_PATCHED_OTA_ZIP_NAME}
}


patch_with_KernelSU
extract_pre_installation
generate_custota_files

