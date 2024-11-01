#!/bin/bash
report_status()
{
    echo -e "\n\n###### $1"
}

update_lnl_os()
{
    report_status "Updating LNLOS"
    SOURCE_DIR="/home/biqu/LNL3dOS"
    TARGER_DIR="/home/biqu/printer_2_data"
    cp SOURCE_DIR TARGET_DIR
}