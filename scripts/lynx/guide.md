### First Installation

<u>Step 1:</u> 	Download OTA zip from `https:/developers.google.com/android/ota#lynx to input/`

<u>Step 2:</u>	Download KernelSU patched boot image from `https://github.com/tiann/KernelSU/releases`, extract to input/
	For `Pixel 7a(lynx)` choose `androidNN-5.10.VV_YYYY-MM-boot.img.gz `
	
<u>Step 3:</u> Run `./patch_n_create_ota.sh input/<OTA zip> input/<KernelSU patched boot image>`

<u>Step 4:</u> Reboot to fastboot and run:</u>

```
fastboot flash init_boot pre-installation/init_boot.img
fastboot flash vendor_boot pre-installation/vendor_boot.img
fastboot flash avb_custom_key signing-keys/lynx_SqK_avb_pkmd.bin
```

<u>Step 5:</u> Note down current boot slot on fastboot screen, then reboot to recovery, sideload patched OTA:</u>

```
adb sideload output/XXXX_PATCHED.zip
```

<u>Step 6:</u> Reboot to fastboot, check if current boot slot has changed, if not, run `fastboot --set-active=other`

<u>Step 7:</u> Reboot to recovery, sideload patched OTA again:</u>

```
adb sideload output/XXXX_PATCHED.zip
```
	
<u>Step 8:</u> Reboot to bootloader, run

```
fastboot flashing lock
```

<u>Step 9:</u> Reboot! Enjoy!

