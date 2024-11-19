#!/bin/bash

# system root directory where printer_n_data folders are created and LNLOS repo is cloned

# Define the PRINTER_DATA_FOLDER_PATTERN for folder names (e.g., "printer_n data" where n is any number), generally 1-3
PRINTER_DATA_FOLDER_PATTERN="printer_[0-9]*_data"
PRINTER_DATA_EXCLUSION_PATTERN="kiauh-backups"

# Define files to search for that have lines to edit
SD_CARD_TARGET_FILE="paths.cfg"
PRINTER_CFG_TARGET_FILE="printer.cfg"
MOONRAKER_TARGET_FILE="moonraker.conf"
SHELL_MACRO_TARGET_FILE="shellmacros.cfg"
INSTALLER_TARGET_FILE="LNLOSSoloInstaller.sh"

# search queries for lines to be updated
VIRTUAL_SD_CARD_SEARCH_PATTERN="path: ~/{printer_data_path}/gcodes"
KLIPPY_UDS_SEARCH_PATTERN="/home/biqu/{printer_data_path}/comms/klippy.sock"
KLIPPY_PORT_SEARCH_PATTERN="port: {klippy_port}"
VARIABLES_LOCATION_SEARCH_PATTERN="filename: ~/{printer_data_path}/config/variables.cfg"
SERIAL_ADDRESS_SEARCH_PATTERN="serial: {serial_port}"
#moonraker LNLOS UpdatePath
MOONRAKER_UPDATE_MANAGER_PATH_PATTERN="path: {LNLOS_INSTALL_PATH}"
#shell macro path 
LNLOS_SHELL_MACRO_INSTALLER_PATTERN="command: /home/biqu/{printer_data_subdir}/LNL3dOS/LNL3dOS/scripts/LNLOSSoloInstaller.sh"

#mcu serial prefix
MCU_SERIAL_PREFIX="serial: "
#rear upper usb port
PRINTER_1_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.2:1.0-port0"
#rear lower usb port
PRINTER_2_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.3:1.0-port0"
#right side usb port
PRINTER_3_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.4:1.0-port0"




# Get the full path of the directory where this script resides
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Identify the "printer_n_data" directory by going three levels up, produces results akin to "/home/biqu/printer_1_data"
PRINTER_DATA_DIR=$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")
# shortened basename version of printer_n_data, ie just printer_1_data not biqu/home/printer_1_data
PRINTER_DATA_SUBDIR=$(basename "$PRINTER_DATA_DIR")

# Define the source and destination directories
# the LNL3dOS parent subdirectory containing config data
SOURCE_DIR="$PRINTER_DATA_DIR/LNL3dOS"
# target config directory
CONFIG_DIR="$PRINTER_DATA_DIR/config"
# target shell macro directory
SCRIPTS_DIR="$CONFIG_DIR/LNL3dOS/scripts"

report_status()
{
    echo -e "\n###### $1"
}

process_solo_directory()
{
    if [[ ! -d "$CONFIG_DIR" ]]; then
        report_status "$CONFIG_DIR" not found, please install klipper with kiauh and try again.
        exit 1
    fi

    if [[ -d "$CONFIG_DIR" ]]; then
        report_status "---------------------------------------------------------------"
        report_status "Processing directory: $CONFIG_DIR"

        # Check if the destination directory exists; if not, create it

        # Transfer all contents from LNL3dOS to config
        report_status "Transferring files from $SOURCE_DIR to $CONFIG_DIR..., printer data dir basename is $PRINTER_DATA_SUBDIR"

        sudo cp -r "$SOURCE_DIR"/* "$CONFIG_DIR"
        
        report_status "File transfer complete."

        # Extract the subdirectory name (e.g., "printer_1_data")
        printer_data_dir_name=$(basename "$printer_data_dir")
        report_status "Working on subdirectory: $CONFIG_DIR"

        # Locate the virtual sd card target file within the current target directory
        sd_target_file_path="$CONFIG_DIR/$SD_CARD_TARGET_FILE"
        report_status "Identified virtual sd card file path should be $sd_target_file_path"

        # Define location of printer.cfg file
        printer_cfg_file_path="$CONFIG_DIR/$PRINTER_CFG_TARGET_FILE"
        report_status "printer cfg file path set to $printer_cfg_file_path"

        # set file path for moonraker.conf file
        moonraker_conf_file_path="$CONFIG_DIR/$MOONRAKER_TARGET_FILE"
        report_status "moonraker conf path set to: $moonraker_conf_file_path"

        # Define the replacement line using the subdirectory name
        virtual_sd_card_line_value="path: ~/$PRINTER_DATA_SUBDIR/gcodes"
        report_status "Identified virtual-sd card should be set to: $virtual_sd_card_line_value"

        # Define line replacement value for variables.cfg
        variables_location_line_value="filename: ~/$PRINTER_DATA_SUBDIR/config/variables.cfg"
        report_status "variables cfg to be set as: $variables_location_line_value"

        # set klippy UDS line value
        klippy_uds_line_value="$PRINTER_DATA_DIR/comms/klippy.sock"
        report_status "klippy UDS line value set to: $klippy_uds_line_value"

        # set moonraker install path value for the update manager
        moonraker_update_manager_path_value="path: $PRINTER_DATA_DIR/LNL3dOS"
        report_status "moonraker update manager path value to be set to: $moonraker_update_manager_path"

        # set installer path for LNLOS shell command
        shell_macro_target_file_path="$SCRIPTS_DIR/$SHELL_MACRO_TARGET_FILE"
        lnlos_installer_path_value="command: /home/biqu/$PRINTER_DATA_SUBDIR/LNL3dOS/LNL3dOS/scripts/$INSTALLER_TARGET_FILE"
        report_status "lnlos updater path value to be set to: $lnlos_installer_path_value"




        # set klippy port value based on printer subdirectory value, printer_1=7125, printer_2=7126, printer_3=7127
        klippy_port_line_value="port: 7125"
        if [ "$PRINTER_DATA_SUBDIR" = "printer_1_data" ]; then
            klippy_port_line_value="port: 7125"
        elif [ "$PRINTER_DATA_SUBDIR" = "printer_2_data" ]; then
            klippy_port_line_value="port: 7126"
        elif [ "$PRINTER_DATA_SUBDIR" = "printer_3_data" ]; then
            klippy_port_line_value="port: 7127"
        else 
            klippy_port_line_value="port: 7125"
        fi
        report_status "klippy port value set to: $klippy_port_line_value"

        mcu_serial_path="serial: {serial_path}"
        if [ "$PRINTER_DATA_SUBDIR" = "printer_1_data" ]; then
            mcu_serial_path="$MCU_SERIAL_PREFIX$PRINTER_1_MCU_SERIAL_PATH"
        elif [ "$PRINTER_DATA_SUBDIR" = "printer_2_data" ]; then
            mcu_serial_path="$MCU_SERIAL_PREFIX$PRINTER_2_MCU_SERIAL_PATH"
        elif [ "$PRINTER_DATA_SUBDIR" = "printer_3_data" ]; then
            mcu_serial_path="$MCU_SERIAL_PREFIX$PRINTER_3_MCU_SERIAL_PATH"
        else
            mcu_serial_path="serial: UNKOWN SERIAL PATH"
        fi
        report_status "set mcu serial path as $mcu_serial_path"

        # Check if the target file exists - paths.cfg
        # replace sd card filepath locations
        if [[ -f "$sd_target_file_path" ]]; then
            # Use sed to find and replace the line
            sed -i "s|$VIRTUAL_SD_CARD_SEARCH_PATTERN|$virtual_sd_card_line_value|" "$sd_target_file_path"
            report_status "Updated '$sd_target_file_path with new path: $virtual_sd_card_line_value"
        else
            report_status "Warning: '$SD_CARD_TARGET_FILE' not found in $printer_data_config_directory"
        fi

        # update variables entries
        if [[ -f "$printer_cfg_file_path" ]]; then
            # Use sed to find and replace the line
            sed -i "s|$VARIABLES_LOCATION_SEARCH_PATTERN|$variables_location_line_value|" "$printer_cfg_file_path"
            report_status "Updated '$printer_cfg_file_path' with variables path: $variables_location_line_value"
        else
            report_status "Warning: '$PRINTER_CFG_TARGET_FILE' not found in $printer_data_config_directory"
        fi

        # update entries for moonraker configuration
        if [[ -f "$moonraker_conf_file_path" ]]; then
            # replace line for klippy port
            sed -i "s|$KLIPPY_PORT_SEARCH_PATTERN|$klippy_port_line_value|" "$moonraker_conf_file_path"
            report_status "Updated '$moonraker_conf_file_path' with new port: $klippy_port_line_value"
            # replace line for klippy uds address
            sed -i "s|$KLIPPY_UDS_SEARCH_PATTERN|$klippy_uds_line_value|" "$moonraker_conf_file_path"
            report_status "Updated '$moonraker_conf_file_path with new UDS Address: $klippy_uds_line_value"
            # replace line for moonraker update manager for lnl3dos
            sed -i "s|$MOONRAKER_UPDATE_MANAGER_PATH_PATTERN|$moonraker_update_manager_path_value|" "$moonraker_conf_file_path"
            report_status "Updated '$moonraker_conf_file_path LNLOS path entry with $moonraker_update_manager_path_value"
        else
            report_status "Warning: '$MOONRAKER_TARGET_FILE' not found in $printer_data_config_directory"
        fi

        # set line value for mcu serial path
        if [[ -f "$printer_cfg_file_path" ]]; then
            # use sed to replace the line
            sed -i "s|$SERIAL_ADDRESS_SEARCH_PATTERN|$mcu_serial_path|" "$printer_cfg_file_path"
            report_status "Updated '$printer_cfg_file_path with new mcu serial path: $mcu_serial_path"
        else
            report_status "Warning: '$PRINTER_CFG_TARGET_FILE' not found in $printer_data_config_directory"
        fi

        if [[ -f "$shell_macro_target_file_path" ]]; then
            sed -i "s|$LNLOS_SHELL_MACRO_INSTALLER_PATTERN|$lnlos_installer_path_value|" "$shell_macro_target_file_path"
            report_status "Updated $shell_macro_target_file_path with new shell command path: $lnlos_installer_path_value"
        else
            report_status "Warning: '$lnlos_installer_path' not found"
        fi



	fi
}

process_solo_directory