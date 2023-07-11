#!/bin/bash
#
# OpenWrt Image Builder script for Xiaomi Redmi Router AC2100
#

echo "[INFO] Looking for new release"
export lastest_release=`curl -s https://downloads.openwrt.org/ | awk '/Stable Release/{p=1}p' | sed -n '/Upcoming\ Stable\ Release/,$b;p' | sed -e 's/<[^>]*>//g' | sed 's/^[[:space:]]*//' | sed -e 's/OpenWrt\ //g' | grep -x '.\{6,10\}'`
export release=${lastest_release}
export profile="xiaomi_redmi-router-ac2100"
export target="ramips"
export subtarget="mt7621"
export image_builder_archive="openwrt-imagebuilder-${release}-${target}-${subtarget}.Linux-x86_64.tar.xz"
export image_builder_dir=`basename -s .tar.xz ${image_builder_archive}`
export manifest_file="openwrt-${release}-${target}-${subtarget}.manifest"

export builddate=`date`
export include_dir="include.d"
export manifest_packages=`cat ${manifest_file} | cut -d ' ' -f1 | tr '\n' ' '`
export extra_packages=`cat extra_packages.txt | tr '\n' ' '`
export packages=`echo ${manifest_packages} ${extra_packages} | tr ' ' '\n' | sort -u | uniq | tr '\n' ' ' `
export build_info="Built at ${builddate} using Image Builder"
export sysupgrade_bin="openwrt-${release}-${target}-${subtarget}-${profile}-squashfs-sysupgrade.bin"

# Download Image Builder archive and manifest file if they don't present
if [ ! -f ${image_builder_archive} ] ; then
	echo "[INFO] New release ${release} is avaibale"
	echo "[INFO] Removing old release"
		rm -r openwrt-imagebuilder-*
	echo "[INFO] Downloading new Image Builder"
		wget https://downloads.openwrt.org/releases/${release}/targets/${target}/${subtarget}/${image_builder_archive} -O ${image_builder_archive}
		wget https://downloads.openwrt.org/releases/${release}/targets/${target}/${subtarget}/${manifest_file} -O ${manifest_file}
	if [ ! -d ${image_builder_dir} ]; then
		echo "[INFO] Extracing Image Builder archive ${image_builder_archive}"
			tar -xf ${image_builder_archive}
	fi
else
	echo "[INFO] Image Builder is up-to-date"
fi


sleep 3
echo "[INFO] Intergating build info to ${include_dir}"
cd ${include_dir}/
build_info_dir="etc/build-info.d"
mkdir -p etc/build-info.d/
find . -type l -o -type f -o -type d > ${build_info_dir}/included_files.txt
echo "${manifest_packages}" > ${build_info_dir}/manifest_packages.txt
echo "${extra_packages}" > ${build_info_dir}/extra_packages.txt
echo "${builddate}" > ${build_info_dir}/build_date.txt
sed -i "s/.*option\ description.*/\toption\ description\ \'${build_info}\'/" etc/config/system


cd ../${image_builder_dir}
mkdir -p tmp
echo "[INFO] Building sysupgrade.bin"
make image PROFILE="${profile}" PACKAGES="${packages}" FILES="../${include_dir}"

cp ../${image_builder_dir}/build_dir/target-mipsel_24kc_musl/linux-${target}_${subtarget}/tmp/${sysupgrade_bin} ..
ls -liah ../${sysupgrade_bin}
