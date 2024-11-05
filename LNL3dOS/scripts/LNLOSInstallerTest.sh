#!/bin/bash

report_status()
{
    echo -e "\n\n###### $1"
}

find_directories()
{
	BASE_DIR="/home/biqu/"

	# Define the pattern for folder names (e.g., "printer_n data" where n is any number)
	PATTERN="printer_[0-9]*_data"
	EXCLUSION="kiauh-backups"

	# Find directories matching the pattern
	report_status "Searching for directories matching pattern '$PATTERN' in '$BASE_DIR'..."
	matching_dirs=$(find "$BASE_DIR" -type d -name "$PATTERN" ! -path "*/$EXCLUSION/*")

	# Check if any directories were found
	if [[ -z "$matching_dirs" ]]; then
    		report_status "No directories found matching the pattern '$PATTERN'."
	else
    		report_status "Directories found:"
    		report_status "$matching_dirs"
	fi



    # Define the name of the file to modify and the line pattern to search
    SD_CARD_TARGET_FILE="paths.cfg"
    SD_SEARCH_PATTERN="path: ~/{printer_data_path}/gcodes"
    PRINTER_CFG_TARGET_FILE="printer.cfg"
    PRINTER_CFG_VARS_SEARCH_PATTERN="~/{printer_data_path}/config/variables.cfg"
    KLIPPY_UDS_PATTERN="/home/biqu/{printer_data_path}/comms/klippy.sock"
    KLIPPY_PORT_PATTERN="port: {klippy_port}"
    MOONRAKER_TARGET_FILE="moonraker.conf"
    PRINTER_CFG_SERIAL_SEARCH_PATTERN="serial: {serial_port}"


    # Check if `matching_dirs` has been set, and exit if it's empty
    if [[ -z "$matching_dirs" ]]; then
        echo "No matching directories found to process. Exiting."
        exit 1
    fi

    # Start processing
    echo "Starting to copy files and modify configurations..."

    # Loop through each target directory in the `matching_dirs` variable
    for target_dir in $matching_dirs; do
        # Check if it's a directory
        if [[ -d "$target_dir" ]]; then
            echo "Processing directory: $target_dir"
        
            # Copy all files from the source directory into the current target directory
            cp -r "$SOURCE_DIR"/* "$target_dir"/

            # Extract the subdirectory name (e.g., "printer_1_data")
            dir_name=$(basename "$target_dir")

            # Define the replacement line using the subdirectory name
            SD_CARD_PATH="path: ~/$dir_name/gcodes"

            # Locate the target file within the current target directory
            sd_target_file_path="$target_dir/$SD_CARD_TARGET_FILE"

            VARIABLES_PATH="filename: ~/$dir_name/config/variables.cfg"
            printer_cfg_file_path="$target_dir/$PRINTER_CFG_TARGET_FILE"



            

            # Check if the target file exists - paths.cfg
            # replace sd card filepath locations
            if [[ -f "$sd_target_file_path" ]]; then
                # Use sed to find and replace the line
                sed -i "s|$SD_SEARCH_PATTERN|$SD_CARD_PATH|" "$sd_target_file_path"
                echo "Updated '$SD_CARD_TARGET_FILE' in $target_dir with new path: $SD_CARD_PATH"
            else
                echo "Warning: '$SD_CARD_TARGET_FILE' not found in $target_dir"
            fi

            # check for variables entries and replace with proper directories
            if [[ -f "$printer_cfg_file_path" ]]; then
                # Use sed to find and replace the line
                sed -i "s|$PRINTER_CFG_VARS_SEARCH_PATTERN|$VARIABLES_PATH|" "$printer_cfg_file_path"
                echo "Updated '$PRINTER_CFG_TARGET_FILE' in $target_dir with new path: $VARIABLES_PATH"
            else
                echo "Warning: '$PRINTER_CFG_TARGET_FILE' not found in $target_dir"
            fi

            # update entries for moonraker configuration
            # TODO replace moonraker klippy UDS addresses
            # TODO replace moonraker port entries
            moonraker_conf_file_path="$target_dir/$MOONRAKER_TARGET_FILE"
            if [[ -f "$moonraker_conf_file_path" ]]; then
                KLIPPY_PORT = "7125"
                KLIPPY_UDS = "/home/biqu/$target_dir/comms/klippy.sock"
                if [ "$dir_name" = "printer_1_data" ]; then
                    KLIPPY_PORT = "7125"
                elif [ "$dir_name" = "printer_2_data" ]; then
                    KLIPPY_PORT = "7126"
                elif [ "$dir_name" = "printer_3_data" ]; then
                    KLIPPY_PORT = "7127"
                else 
                    KLIPPY_PORT = "7125"
                fi
                # Use sed to find and replace the line
                sed -i "s|$KLIPPY_PORT_PATTERN|$KLIPPY_PORT|" "$moonraker_conf_file_path"
                echo "Updated '$MOONRAKER_TARGET_FILE' in $target_dir with new port: $KLIPPY_PORT"
                sed -1 "s|$KLIPPY_UDS_PATTERN|$KLIPPY_UDS|" "$moonraker_conf_file_path"
                echo "Updated '$MOONRAKER_TARGET_FILE' in $target_dir with new UDS Address: $KLIPPY_UDS"
            else
                echo "Warning: '$MOONRAKER_TARGET_FILE' not found in $target_dir"
            fi



            # TODO TEST serial MCU path 
            # rear upper usb port
            # /dev/serial/by-path/platform-5200000.usb-usb-0:1.2:1.0-port0
            # rear lower usb port
            # /dev/serial/by-path/platform-5200000.usb-usb-0:1.3:1.0-port0
            # side usb port
            # /dev/serial/by-path/platform-5200000.usb-usb-0:1.4:1.0-port0
            if [[ -f "$printer_cfg_file_path" ]]; then
                SERIAL_PATH = "{serial_path}"
                if [ "$dir_name" = "printer_1_data" ]; then
                    SERIAL_PATH = "/dev/serial/by-path/platform-5200000.usb-usb-0:1.2:1.0-port0" 
                elif [ "$dir_name" = "printer_2_data" ]; then
                    SERIAL_PATH = "/dev/serial/by-path/platform-5200000.usb-usb-0:1.3:1.0-port0"
                elif [ "$dir_name" = "printer_3_data" ]; then
                    SERIAL_PATH = "/dev/serial/by-path/platform-5200000.usb-usb-0:1.4:1.0-port0"
                else 
                    SERIAL_PATH = "{unknown_serial_path}"
                fi
                    # Use sed to find and replace the line
                sed -i "s|$PRINTER_CFG_SERIAL_SEARCH_PATTERN|$SERIAL_PATH|" "$printer_cfg_file_path"
                echo "Updated '$PRINTER_CFG_TARGET_FILE' in $target_dir with new path: $SERIAL_PATH"
            else
                echo "Warning: '$PRINTER_CFG_TARGET_FILE' not found in $target_dir"
            fi


        fi
    done

echo "Completed processing all directories."


}


# exit script if any errors
find_directories