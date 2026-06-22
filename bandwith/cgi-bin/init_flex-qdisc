#!/bin/sh /etc/rc.common

USE_PROCD=1

. /lib/functions.sh

START=99

extra_command "remove" "Uninstall the program"

CONFIGURATION=flex-qdisc

start_service() {
    # Reading config
    config_load "${CONFIGURATION}"
    
    local device interval safety
    local download upload alpha
    local delta_download delta_upload

    config_get device default device    
    config_get interval default interval    
    config_get safety default safety    
    config_get download default download    
    config_get upload default upload    
    config_get alpha default alpha    
    config_get delta_download default delta_download    
    config_get delta_upload default delta_upload

    procd_open_instance

    procd_set_param command \
        /etc/flex-qdisc/flex-qdisc \
        "$device" \
        "$interval" \
        "$safety" \
        "$download" \
        "$upload" \
        "$alpha" \
        "$delta_download" \
        "$delta_upload"

    procd_set_param respawn

    procd_close_instance

    echo "Success flex-qdisc config setup!";
    echo
}

stop_service() {
    # Reading config
    config_load "${CONFIGURATION}"
    
    local device

    /etc/flex-qdisc/stop "$device"

    config_get device default device
}

remove() {
    /etc/flex-qdisc/remove
}