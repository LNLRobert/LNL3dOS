#!/bin/bash
report_status()
{
    echo -e "\n\n###### $1"
}

update_lnl_os()
{
    report_status "Updating LNLOS"
    SOURCE_DIR="~/LNL3dOS"
    TARGER_DIR="~/printer_3_data"
    sudo cp SOURCE_DIR TARGET_DIR
}


# exit script if any errors
update_lnl_os