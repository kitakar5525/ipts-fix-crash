#!/bin/bash

readonly STR_CRASH="547D"
readonly IPTS_DBG_INFO_FILE="/sys/kernel/debug/ipts/debug"
readonly IPTS_MODE_FILE="/sys/kernel/debug/ipts/mode"



function is_crashed() {
    fw_status=$(sudo cat $IPTS_DBG_INFO_FILE | grep "fw status" | awk -F": " '{print $3}')
    str=${fw_status:4:4}
    if [ $str = $STR_CRASH ]; then
        echo true
    else
        echo false
    fi
}

while true; do
    if $(is_crashed); then
        echo 0 | sudo tee $IPTS_MODE_FILE
        echo 0 | sudo tee $IPTS_MODE_FILE
        sleep 0.5
        echo 1 | sudo tee $IPTS_MODE_FILE
        echo "touch fixed."
        sleep 0.5
    fi

    sleep 1
done