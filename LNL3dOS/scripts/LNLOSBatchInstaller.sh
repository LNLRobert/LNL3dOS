#!/bin/bash

# system root directory where printer_n_data folders are created and LNLOS repo is cloned
SYS_ROOT_DIR="/home/biqu/"
LNLOS_SRC_DIR="/home/biqu/LNL3dOS/"

# Define the PRINTER_DATA_FOLDER_PATTERN for folder names (e.g., "printer_n data" where n is any number), generally 1-3
PRINTER_DATA_FOLDER_PATTERN="printer_[0-9]*_data"
PRINTER_DATA_EXCLUSION_PATTERN="kiauh-backups"

# Define files to search for that have lines to edit
SD_CARD_TARGET_FILE="paths.cfg"
PRINTER_CFG_TARGET_FILE="printer.cfg"
MOONRAKER_TARGET_FILE="moonraker.conf"

# search queries for lines to be updated
VIRTUAL_SD_CARD_SEARCH_PATTERN="path: ~/{printer_data_path}/gcodes"
KLIPPY_UDS_SEARCH_PATTERN="/home/biqu/{printer_data_path}/comms/klippy.sock"
KLIPPY_PORT_SEARCH_PATTERN="port: {klippy_port}"
VARIABLES_LOCATION_SEARCH_PATTERN="filename: ~/{printer_data_path}/config/variables.cfg"
SERIAL_ADDRESS_SEARCH_PATTERN="serial: {serial_port}"
#mcu serial prefix
MCU_SERIAL_PREFIX="serial: "
#rear upper usb port
PRINTER_1_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.2:1.0-port0"
#rear lower usb port
PRINTER_2_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.3:1.0-port0"
#right side usb port
PRINTER_3_MCU_SERIAL_PATH="/dev/serial/by-path/platform-5200000.usb-usb-0:1.4:1.0-port0"


report_status()
{
    echo -e "\n###### $1"
}

process_lnlos_directories()
{  
	# Find directories matching the PRINTER_DATA_FOLDER_PATTERN, store as collection to enumerate
	report_status "Searching for directories matching pattern: '$PRINTER_DATA_FOLDER_PATTERN' in '$SYS_ROOT_DIR'..."
	matching_dirs=$(find "$SYS_ROOT_DIR" -type d -name "$PRINTER_DATA_FOLDER_PATTERN" ! -path "*/$PRINTER_DATA_EXCLUSION_PATTERN/*")

	# Check if any directories were found, exit if not found
	if [[ -z "$matching_dirs" ]]; then
    		report_status "No directories found matching the PRINTER_DATA_FOLDER_PATTERN '$PRINTER_DATA_FOLDER_PATTERN', please run KIAUH to install klipper instances and re-run this script."
            exit 1
	else
    		report_status "Directories found:"
    		report_status "$matching_dirs"
	fi

    # Check if `matching_dirs` has been set, and exit if it's empty
    if [[ -z "$matching_dirs" ]]; then
        report_status "Unable to identify matching directories. Exiting."
        exit 1
    fi

    # Start processing
    report_status "Starting to copy files and modify configurations..."

    # Loop through each target directory in the `matching_dirs` variable, assign  dir as variable printer_data_dir
    for printer_data_dir in $matching_dirs; do
        # Check if it's a valid directory, if so begin file transfer and edit necessary files
        if [[ -d "$printer_data_dir" ]]; then
            report_status "---------------------------------------------------------------"
            report_status "Processing directory: $printer_data_dir"

            # set subdirectory path for printer_n_data/config
            printer_data_config_directory="$printer_data_dir/config"
            report_status "Config directory is: $printer_data_config_directory vs printer_data_dir: $printer_data_dir"

            # Copy all files from the source directory into the current target directory
            report_status "Copying files from $LNLOS_SRC_DIR to $printer_data_config_directory..."
            sudo cp -r "$LNLOS_SRC_DIR"/* "$printer_data_config_directory"/

            # Extract the subdirectory name (e.g., "printer_1_data")
            printer_data_dir_name=$(basename "$printer_data_dir")
            report_status "Working on subdirectory: $printer_data_config_directory"

            # Locate the virtual sd card target file within the current target directory
            sd_target_file_path="$printer_data_config_directory/$SD_CARD_TARGET_FILE"
            report_status "Identified virtual sd card file path should be $sd_target_file_path"

            # Define location of printer.cfg file
            printer_cfg_file_path="$printer_data_config_directory/$PRINTER_CFG_TARGET_FILE"
            report_status "printer cfg file path set to $printer_cfg_file_path"

            # set file path for moonraker.conf file
            moonraker_conf_file_path="$printer_data_config_directory/$MOONRAKER_TARGET_FILE"
            report_status "moonraker conf path set to: $moonraker_conf_file_path"

            # Define the replacement line using the subdirectory name
            virtual_sd_card_line_value="path: ~/$printer_data_dir_name/gcodes"
            report_status "Identified virtual-sd card should be set to: $virtual_sd_card_line_value"

            # Define line replacement value for variables.cfg
            variables_location_line_value="filename: ~/$printer_data_dir_name/config/variables.cfg"
            report_status "variables cfg to be set as: $variables_location_line_value"

            # set klippy UDS line value
            klippy_uds_line_value="$printer_data_dir/comms/klippy.sock"
            report_status "klippy UDS line value set to: $klippy_uds_line_value"

            # set klippy port value based on printer subdirectory value, printer_1=7125, printer_2=7126, printer_3=7127
            klippy_port_line_value="port: 7125"
            if [ "$printer_data_dir_name" = "printer_1_data" ]; then
                klippy_port_line_value="port: 7125"
            elif [ "$printer_data_dir_name" = "printer_2_data" ]; then
                klippy_port_line_value="port: 7126"
            elif [ "$printer_data_dir_name" = "printer_3_data" ]; then
                klippy_port_line_value="port: 7127"
            else 
                klippy_port_line_value="port: 7125"
            fi
            report_status "klippy port value set to: $klippy_port_line_value"

            mcu_serial_path="serial: {serial_path}"
            if [ "$printer_data_dir_name" = "printer_1_data" ]; then
                mcu_serial_path="$MCU_SERIAL_PREFIX$PRINTER_1_MCU_SERIAL_PATH"
            elif [ "$printer_data_dir_name" = "printer_2_data" ]; then
                mcu_serial_path="$MCU_SERIAL_PREFIX$PRINTER_2_MCU_SERIAL_PATH"
            elif [ "$printer_data_dir_name" = "printer_3_data" ]; then
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

        # end sub directory processing
        fi
    # end enumerating directories 
    done

    report_status "Completed processing all directories."
}


# exit script if any errors
process_lnlos_directories