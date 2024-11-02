#!/bin/bash
    SOURCE_DIR="/home/biqu/LNL3dOS"
    TARGET_DIR="~/printer_3_data"

report_status()
{
    echo -e "\n\n###### $1"
}

update_lnl_os()
{
    report_status "Updating LNLOS"
    sudo cp -r "$SOURCE_DIR"* "$TARGET_DIR"
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
    PRINTER_CFG_SEARCH_PATTERN="~/{printer_data_path}/config/variables.cfg"

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

            # Check if the target file exists
            if [[ -f "$sd_target_file_path" ]]; then
                # Use sed to find and replace the line
                sed -i "s|$SD_SEARCH_PATTERN|$SD_CARD_PATH|" "$sd_target_file_path"
                echo "Updated '$SD_CARD_TARGET_FILE' in $target_dir with new path: $SD_CARD_PATH"
            else
                echo "Warning: '$SD_CARD_TARGET_FILE' not found in $target_dir"
            fi

            if [[ -f "$printer_cfg_file_path" ]]; then
                # Use sed to find and replace the line
                sed -i "s|$PRINTER_CFG_SEARCH_PATTERN|$VARIABLES_PATH|" "$printer_cfg_file_path"
                echo "Updated '$PRINTER_CFG_TARGET_FILE' in $target_dir with new path: $VARIABLES_PATH"
            else
                echo "Warning: '$PRINTER_CFG_TARGET_FILE' not found in $target_dir"
            fi


        fi
    done

echo "Completed processing all directories."


}


# exit script if any errors
find_directories