#!/bin/bash
#
# Descritpion: 
# This script:
# - Checks for avbroot and custota-tool update
# - Patchs OTA zip with kernelsu boot image
# - Extracts boot images from patched OTA zip for flashing OTA the first time
# - Generates Custota json and csig file for OTA server
#
# Input: KernelSU boot image, stock OTA zip. They should be(optional) put in input/ directory
# Output: patched OTA zip, custota json, custota csig files in output/ directory
#
#
## INITIAL SETUP GUIDE:
# - Do this when the the phone is still on stock ROM
# 1. Reboot to fastboot and run:
#	for flash_image in extracted-ota/*.img; do
#		partition=$(basename "${image}")
#		partition=${partition%.img}
#
#		fastboot flash "${partition}" "${image}"
#	done
#	fastboot erase avb_custom_key
#	fastboot flash avb_custom_key signing-keys/lynx_SqK_avb_pkmd.bin
# 2. Note down current boot slot on fastboot screen, then reboot to recovery, sideload patched OTA:
#	adb sideload output/XXXX_PATCHED.zip
# 3. Reboot to fastboot, check if current boot slot has changed, if not, run fastboot --set-active=other
# 4. Reboot to recovery, sideload patched OTA again:
#	adb sideload output/XXXX_PATCHED.zip
# 5. Reboot to bootloader, run
#	fastboot flashing lock
# 6. Reboot! Enjoy!
#
#
## UPDATE GUIDE:
# - Do this when there a patched OTA zip is has already been flashed and the bootloader is re-locked
# 1. Download latest OTA zip and kernelsu boot image
#     OTA zip URL: https:/developers.google.com/android/ota#lynx
#     kernelsu URL: https://github.com/tiann/kernelsu/releases/latest, download androidNN-5.10.VV_YYYY-MM-boot.img.gz 
# 1. Run ./patch_n_create_ota.zip <path/to/OTA_zip_file> <path/to/kernelsu_boot_image>
# 2. Put 3 files from /output directory to http server with path <document root>/Android_OTA/lynx/
# 3. On Custota app: Set URL: http://<IP>/Android_OTA/lynx/
# 4. On Custota app: Tick on "Check for update and install update"
# 5. Reboot your phone
#



#====================> CONFIG HERE <=====================
# OTA patching
export DEVICE_CODENAME="lynx"

export AVB_KEY="signing-keys/lynx_SqK_avb.key"
export OTA_KEY="signing-keys/lynx_SqK_ota.key"
export OTA_CRT="signing-keys/lynx_SqK_ota.crt"

export PASSPHRASE_AVB=""
export PASSPHRASE_OTA=""

# OTA server
OTA_SERVER_SSH_HOST="raspi" # Need pre-configured with ~/.ssh/config
OTA_SERVER_OTA_PATH="/storage/www/Android_OTA/lynx/" # Path on remote host where a webserver is configured
#========================================================




function show_syntax() {
	echo "./$(basename "$0") <OTA zip> <kernelsu patched GKI>"
	exit 1
}


function update_binaries() {
	avbroot_latest_url="https://github.com/chenxiaolong/avbroot/releases/latest"
	avbroot_latest_ver=`curl -Ls -o /dev/null -w %{url_effective} ${avbroot_latest_url} | tr '/' '\n' | tail -n 1 | tr -d 'v'`
	avbroot_download_url="https://github.com/chenxiaolong/avbroot/releases/download/v${avbroot_latest_ver}/avbroot-${avbroot_latest_ver}-x86_64-unknown-linux-gnu.zip"

	custota_latest_url="https://github.com/chenxiaolong/custota/releases/latest"
	custota_latest_ver=`curl -Ls -o /dev/null -w %{url_effective} ${custota_latest_url} | tr '/' '\n' | tail -n 1 | tr -d 'v'`
	custota_download_url="https://github.com/chenxiaolong/custota/releases/download/v${custota_latest_ver}/custota-tool-${custota_latest_ver}-x86_64-unknown-linux-gnu.zip"

	if [ ! -f bin/avbroot_${avbroot_latest_ver} ]; then
		echo "[info] Updating avbroot to version ${avbroot_latest_ver}"
		wget -q ${avbroot_download_url} -O tmp/avbroot_${avbroot_latest_ver}.zip
		unzip -p tmp/avbroot_${avbroot_latest_ver}.zip avbroot > bin/avbroot_${avbroot_latest_ver} && chmod +x bin/avbroot_${avbroot_latest_ver}
		[ -L bin/avbroot ] && rm bin/avbroot
	else
		echo "[info] avbroot is up-to-date with version ${avbroot_latest_ver}"
	fi
	[ ! -L bin/avbroot ] && ln -s avbroot_${avbroot_latest_ver} bin/avbroot

	if [ ! -f bin/custota-tool_${custota_latest_ver} ]; then
		echo "[info] Updating custota-tool to version ${custota_latest_ver}"
		wget -q ${custota_download_url} -O tmp/custota_${custota_latest_ver}.zip
		unzip -p tmp/custota_${custota_latest_ver}.zip custota-tool > bin/custota-tool_${custota_latest_ver} && chmod +x bin/custota-tool_${custota_latest_ver}
		[ -L bin/custota-tool ] && rm bin/custota-tool
	else
		echo "[info] custota-tool is up-to-date with version ${custota_latest_ver}"
	fi
	[ ! -L bin/custota-tool ] && ln -s custota-tool_${avbroot_latest_ver} bin/custota-tool
	
}


function patch_with_kernelsu() {
	echo -e "[info] Patching OTA zip: ${OTA_ZIP} using kernelsu patched boot image: ${KERNELSU_BOOT_IMG}"
	bin/avbroot \
		ota patch \
		--input ${OTA_ZIP} \
		--privkey-avb ${AVB_KEY} \
		--privkey-ota ${OTA_KEY} \
		--cert-ota ${OTA_CRT} \
		--prepatched ${KERNELSU_BOOT_IMG} \
		--boot-partition @gki_kernel \
		--ignore-prepatched-compat --ignore-prepatched-compat\
		--clear-vbmeta-flags \
		--passphrase-avb-env-var PASSPHRASE_AVB \
		--passphrase-ota-env-var PASSPHRASE_OTA \
		--output ${KERNELSU_PATCHED_OTA_ZIP_NAME}
}


function extract_pre_installation() {
	echo "[info] Extracting boot images to be flashed by fastboot"
	bin/avbroot \
		ota extract \
		--input ${KERNELSU_PATCHED_OTA_ZIP_NAME} \
		--directory extracted-ota
}


function generate_custota_files() {
	echo "[info] Generating Custota files for Custota OTA server"
	bin/custota-tool \
		gen-csig \
		--input ${KERNELSU_PATCHED_OTA_ZIP_NAME} \
		--key ${OTA_KEY}\
		--cert ${OTA_CRT} \
		--passphrase-env-var PASSPHRASE_OTA

	bin/custota-tool \
		gen-update-info \
		--file ${DEVICE_CODENAME}.json \
		--location ${KERNELSU_PATCHED_OTA_ZIP_NAME}
}


function copy_to_http_server() {
	ssh -qn ${OTA_SERVER_SSH_HOST} find ${OTA_SERVER_OTA_PATH} -maxdepth 1 -type f -type d -delete
	for OTA_files in ${DEVICE_CODENAME}.json ${KERNELSU_PATCHED_OTA_ZIP_NAME}.csig ${KERNELSU_PATCHED_OTA_ZIP_NAME}; do
		scp output/${OTA_files} ${OTA_SERVER_SSH_HOST}:${OTA_SERVER_OTA_PATH}
	done
}



OTA_ZIP="$1"
KERNELSU_BOOT_IMG="$2"

[ ! -f "${OTA_ZIP}" ] && { echo "OTA zip doesn't exist"; show_syntax; }
[ ! -f "${KERNELSU_BOOT_IMG}" ] && { echo "kernelsu patched GKI doesn't exist"; show_syntax; }

KERNELSU_PATCHED_OTA_ZIP_NAME=`echo $(basename -s .zip ${OTA_ZIP})_$(basename -s .img ${KERNELSU_BOOT_IMG})_PATCHED.zip`

mkdir -p bin
mkdir -p output
mkdir -p extracted-ota

find output/ -maxdepth 1 -type f -type d -delete


update_binaries
patch_with_kernelsu
extract_pre_installation
generate_custota_files
for output_file in ${KERNELSU_PATCHED_OTA_ZIP_NAME} ${DEVICE_CODENAME}.json ${KERNELSU_PATCHED_OTA_ZIP_NAME}.csig; do
	mv ${output_file} output/
done
copy_to_http_server


