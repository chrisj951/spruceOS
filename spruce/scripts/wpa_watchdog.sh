#!/bin/sh

##### GENERAL #####

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

case "$PLATFORM" in
    "Brick" | "SmartPro" )
        WPA_FILE="/etc/wifi/wpa_supplicant.conf"
        TEMP_FILE="/etc/wifi/wpa_supplicant_temp.conf"
    ;;
    "Flip" )
        WPA_FILE="/userdata/cfg/wpa_supplicant.conf"
        TEMP_FILE="/userdata/cfg/wpa_supplicant_temp.conf"
    ;;
    "A30" )
        WPA_FILE="/config/wpa_supplicant.conf"
        TEMP_FILE="/config/wpa_supplicant_temp.conf"
    ;;
esac

MULTIPASS="/mnt/SDCARD/multipass.cfg"

##### MULTIPASS.CFG #####

append_network_from_multipass() {
}

get_psk() {

}

