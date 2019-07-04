#!/bin/bash

# When the touch crash happens, the sixth number (zero-based) of `fw_status`
# will become '7'.
readonly NUM_CRASH="7"
# TODO: Is this path vaild on all the other devices? `0000:00:16.4` may vary between devices. 
# I want to know a permanent path. This path is valid at least on SB1.
# Also, we can't use `/sys/class/mei/mei0/fw_status` because the number of meiN may vary after reboot.
readonly MEI_FW_STATUS_FILE=$(find /sys/devices/pci0000:00/0000:00:16.4 -name fw_status)
readonly IPTS_MODE_FILE="/sys/kernel/debug/ipts/mode"



function is_crashed() {
    fw_status=$(cat $MEI_FW_STATUS_FILE)
    num=${fw_status:6:1} # if $num is 7, we consider ME FW is being wrong.
    
    if [ $num = $NUM_CRASH ]; then
        echo true
    else
        echo false
    fi
}

while true; do
    if $(is_crashed); then
        # commands for fixing touch input

        # change sensor mode
        echo 0 | sudo tee $IPTS_MODE_FILE
        echo 0 | sudo tee $IPTS_MODE_FILE
        sleep 0.5
        echo 1 | sudo tee $IPTS_MODE_FILE
        echo "touch fixed."
        sleep 0.5

        # Or display off
        # xset dpms force off && xset dpms force on
    fi

    sleep 1
done