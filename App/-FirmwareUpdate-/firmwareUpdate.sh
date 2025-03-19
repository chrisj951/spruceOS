#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

SD_ROOT="/mnt/SDCARD"
FW_DIR="/mnt/SDCARD/spruce/FIRMWARE_UPDATE"
case "$PLATFORM" in
	"A30" ) FW_FILE="miyoo282_fw.img" ;;
	"Flip" ) FW_FILE="miyoo353_fw.img" ;;
	"Brick" ) FW_FILE="trimui_tg3040.awimg" ;;
	"SmartPro" ) FW_FILE="trimui_tg5040.awimg" ;;
esac

[ "$PLATFORM" = "SmartPro" ] && BG_IMAGE="/mnt/SDCARD/spruce/imgs/bg_tree_wide.png" || BG_IMAGE="/mnt/SDCARD/spruce/imgs/bg_tree.png"

# get the free space on the SD card in MiB
FREE_SPACE="$(df -m /mnt/SDCARD | awk '{print $4}' | tail -n 1)"

CHARGING="$(cat /sys/devices/platform/axp22_board/axp22-supplyer.20/power_supply/battery/online)"
CAPACITY="$(cat /sys/devices/platform/axp22_board/axp22-supplyer.20/power_supply/battery/capacity)"

NEEDS_UPDATE=true

case "$PLATFORM" in
	"A30" )
		SPACE_NEEDED=48
		VERSION="$(cat /usr/miyoo/version)"
		if [ "$VERSION" -ge 20240713100458 ]; then
			NEEDS_UPDATE=false
		fi
		;;
	"Flip" )
		SPACE_NEEDED=384
		VERSION="$(cat /usr/miyoo/version)"
		if [ "$VERSION" -ge 20250228101926 ]; then
			NEEDS_UPDATE=false
		fi
		;;
	"Brick" )
		SPACE_NEEDED=1280
		VERSION="$(cat /etc/version)"
		v_major="$(cut -d '.' -f 1 "$VERSION")"
		# v_minor="$(cut -d '.' -f 2 "$VERSION")"
		v_bug="$(cut -d '.' -f 3 "$VERSION")"
		if [ "$v_major" -ge 1 ] && [ "$v_bug" -ge 6 ]; then
			NEEDS_UPDATE=false
		fi
		;;
	"SmartPro" )
		SPACE_NEEDED=768
		VERSION="$(cat /etc/version)"
		v_major="$(cut -d '.' -f 1 "$VERSION")"
		# v_minor="$(cut -d '.' -f 2 "$VERSION")"
		v_bug="$(cut -d '.' -f 3 "$VERSION")"
		if [ "$v_major" -ge 1 ] && [ "$v_bug" -ge 4 ]; then
			NEEDS_UPDATE=false
		fi
		;;
esac

# Debugging Variables
SKIP_VERSION_CHECK=false
SKIP_APPLY=false

log_message "firmwareUpdate.sh: free space: $FREE_SPACE"
log_message "firmwareUpdate.sh: charging status: $CHARGING"
log_message "firmwareUpdate.sh: current charge percent: $CAPACITY"
log_message "firmwareUpdate.sh: current FW version: $VERSION"

cancel_update() {
	log_message "firmwareUpdate.sh: Firmware update cancelled."
	display -i "$BG_IMAGE" -o -t "Firmware update cancelled."
	if [ -f "$SD_ROOT/$FW_FILE" ]; then
		rm "$SD_ROOT/$FW_FILE"
		log_message "Removing FW image from root of card."
	fi
	exit 1
}

confirm_update() {
	if [ ! -f "$SD_ROOT/$FW_FILE" ]; then
		display -i "$BG_IMAGE" -d 2 -t "Moving firmware update file into place."
		7zr x "$FW_DIR/$FW_FILE.7z" -o"$SD_ROOT/"
	fi
	display -i "$BG_IMAGE" -t "Your $PLATFORM will now shut down. Please manually power your device back on while plugged in to complete the manufacturer firmware update. Once started, please be patient, as it will take a few minutes. It will power itself down again once complete." -p 140 -o
	flag_add "first_boot_$PLATFORM"
	sync
	poweroff
}

if [ "$SKIP_VERSION_CHECK" = false ] && [ "$NEEDS_UPDATE" = false ]; then
	log_message "firmwareUpdate.sh: Firmware already up to date. Hiding -FirmwareUpdate- App."
	display -i "$BG_IMAGE" -o -t "Firmware is up to date - happy gaming!!!!!!!!!!"
	sed -i 's|"label":|"#label":|' "$CONFIG"
	exit 0
else
	log_message "firmwareUpdate.sh: Firmware requires update. Continuing."
fi

display -i "$BG_IMAGE" -t "A firmware update from the manufacturer is ready for your device. We'll check your device's status and prepare the manufacturer update file. Once set up, the manufacturer firmware updater will install it." -o -p 160

if [ "$FREE_SPACE" -lt "$SPACE_NEEDED" ]; then
	log_message "firmwareUpdate.sh: Not enough free space on card. Aborting."
	display -i "$BG_IMAGE" -o -t "Not enough free space. Please ensure at least $SPACE_NEEDED MiB of space is available on your SD card, then try again."
	exit 1
else
	log_message "firmwareUpdate.sh: SD card contains at least $SPACE_NEEDED MiB free space. Continuing."
fi

if [ "$CAPACITY" -lt 10 ]; then
	log_message "firmwareUpdate.sh: Not enough charge on device. Aborting."
	display -i "$BG_IMAGE" -o -t "As a precaution, please charge your $PLATFORM to at least 10% capacity, then try again."
	exit 1
else
	log_message "firmwareUpdate.sh: Device has at least 10% charge. Continuing."
fi

if [ "$CHARGING" -eq 0 ]; then
	log_message "firmwareUpdate.sh: Device not plugged in. Prompting user to plug in their $PLATFORM."
	while true; do
		display -i "$BG_IMAGE" -t "Please connect your device to a power source to proceed with the update process." --confirm
		if confirm; then
			# Re-evaluate charging status
			CHARGING="$(cat /sys/devices/platform/axp22_board/axp22-supplyer.20/power_supply/battery/online)"
			if [ "$CHARGING" -eq 1 ]; then
				log_message "firmwareUpdate.sh: Device is now plugged in. Continuing."
				break
			else
				log_message "firmwareUpdate.sh: Device still not plugged in after user pressed A."
				display -i "$BG_IMAGE" -d 3 -t "Did not detect device charging. You must plug in your device before continuing."
			fi
		else
			log_message "firmwareUpdate.sh: User cancelled update while waiting for device to be plugged in."
			cancel_update
		fi
	done
else
	log_message "firmwareUpdate.sh: Device is plugged in at first charging check. Continuing."
fi

if [ "$CHARGING" -eq 1 ]; then
	log_message "firmwareUpdate.sh: Device is plugged in. Prompting for A to proceed or B to cancel."
	display -i "$BG_IMAGE" -t "WARNING: If unplugged or powered off before the update is complete, your device could become temporarily bricked, requiring you to run the unbricker software." --okay
	if confirm; then
		log_message "firmwareUpdate.sh: A button pressed. Confirming update."
		if [ "$SKIP_APPLY" = false ]; then
			log_message "firmwareUpdate.sh: Confirming update."
			confirm_update
		fi
	else
		log_message "firmwareUpdate.sh: B button pressed. Cancelling update."
		cancel_update
	fi

else
	display -d 3 -i "$BG_IMAGE" -t "Exiting Firmware Update app. Please try again once you have plugged in your $PLATFORM."
	log_message "firmwareUpdate.sh: Device still not plugged in. Aborting."
fi
