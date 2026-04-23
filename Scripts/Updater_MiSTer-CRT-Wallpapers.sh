#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 2020 - RetroDriven and Ranny Snice
# You can download the latest version of this script from:
# https://github.com/RetroDriven/MiSTer-CRT-Wallpapers
# v2.0 - Switched to GitHub DB-based download

#=========   URL OPTIONS   =========

# Main URL (GitHub)
MAIN_URL="https://github.com"

# Wallpaper Database URL (db.json.zip contains file list with hash, size, tags)
DB_URL="https://raw.githubusercontent.com/Ranny-Snice/Ranny-Snice-Wallpapers/db/db.json.zip"

#=========   USER OPTIONS   =========

# Choose if you'd like to manage the Wallpapers that appear on your MiSTer Menu
# Set to "False" if you'd like your MiSTer to randomly select a Wallpaper from everything downloaded
# Set to "True" if you'd like to manually manage/copy from /wallpapers/subfolders to /wallpapers 
SELF_MANAGED="False"

# Case Sensitive Keywords to Skip Downloading Wallpapers that you do not want
# NOTE: The list is separated by space so only use part of the word if it's more than one word
# EXAMPLE: BLACKLIST="Powerpuff Bowsette Vampire"
BLACKLIST=""

#========= DO NOT CHANGE BELOW =========

# Record script execution timestamp
TIMESTAMP=`date "+%m-%d-%Y @ %I:%M%P"`
# Allow insecure SSL connection (fix certificate issues)
ALLOW_INSECURE_SSL="true"
# curl retry parameters (15s connect timeout, 120s max time, 3 retries, 5s delay)
CURL_RETRY="--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5"

# Get script path (supports pipe execution: curl ... | bash - )
ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]
then
    # If called via pipe, get parent process name from process list
	ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi

# Load INI config file with same name (user custom configuration)
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini
if [ -f $INI_PATH ]
then
    # Read INI file and execute, tr -d '\r' removes Windows line endings
	eval "$(cat $INI_PATH | tr -d '\r')"
fi

# Compatibility: migrate old path to new path
if [ -d "${BASE_PATH}/${OLD_SCRIPTS_PATH}" ] && [ ! -d "${BASE_PATH}/${SCRIPTS_PATH}" ]
then
	mv "${BASE_PATH}/${OLD_SCRIPTS_PATH}" "${BASE_PATH}/${SCRIPTS_PATH}"
	echo "Moved"
	echo "${BASE_PATH}/${OLD_SCRIPTS_PATH}"
	echo "to"
	echo "${BASE_PATH}/${SCRIPTS_PATH}"
	echo "Please relaunch the script."
	exit 3
fi

# SSL certificate verification handling
SSL_SECURITY_OPTION=""
curl $CURL_RETRY -q $MAIN_URL &>/dev/null
case $? in
	0)
		;;  # Connection successful, no action needed
	60)
        # SSL certificate verification failed
		if [ "$ALLOW_INSECURE_SSL" == "true" ]
		then
			SSL_SECURITY_OPTION="--insecure"  # Allow insecure connection
		else
			echo "CA certificates need to be fixed for using SSL certificate verification."
			echo "Please fix them i.e. using security_fixes.sh"
			exit 2
		fi
		;;
	*)
		echo "No Internet connection"
		exit 1
		;;
esac

#========= FUNCTIONS =========

# RetroDriven Updater Banner Function
RetroDriven_Banner(){
echo
echo " ------------------------------------------------------------"
echo "|                   MiSTer CRT Wallpapers v2.0               |"
echo "|                   powered by RetroDriven                   |"
echo " ------------------------------------------------------------"
sleep 3  # Pause 3 seconds for visibility
}

# Download Wallpapers Function
Download_Wallpapers(){

    echo
    echo "================================================================"
    echo "                 Downloading MiSTer CRT Wallpapers              "
    echo "================================================================"
	sleep 1

    # Create wallpaper storage directory
	mkdir -p "/media/fat/wallpapers"
    cd "/media/fat/wallpapers"

    # If old menu.jpg/png exists, move to wallpapers directory and rename
	if [ -f /media/fat/menu.jpg ]; then
		mv -f "/media/fat/menu.jpg" "/media/fat/wallpapers/menu2.jpg" 2>/dev/null
	fi
	if [ -f /media/fat/menu.png ]; then
		mv -f "/media/fat/menu.png" "/media/fat/wallpapers/menu2.png" 2>/dev/null
	fi

    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    
    # Step 1: Download db.json.zip
    echo
    echo "Downloading wallpaper database..."
    echo
    curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} -L -o "${TMP_DIR}/db.json.zip" "$DB_URL"
    
    if [ ! -f "${TMP_DIR}/db.json.zip" ] || [ ! -s "${TMP_DIR}/db.json.zip" ]; then
        echo "Failed to download database!"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Step 2: Extract db.json from zip
    echo "Extracting database..."
    unzip -q "${TMP_DIR}/db.json.zip" -d "$TMP_DIR" 2>/dev/null
    
    if [ ! -f "${TMP_DIR}/db.json" ]; then
        echo "Error: db.json not found in zip archive!"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Step 3: Parse base_files_url from db.json
    # JSON format: {"base_files_url": "https://raw.githubusercontent.com/.../<commit_hash>/", ...}
    # This URL is the base for all file downloads
    BASE_FILES_URL=$(grep -o '"base_files_url"[[:space:]]*:[[:space:]]*"[^"]*"' "${TMP_DIR}/db.json" | \
        sed 's/.*"base_files_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    
    if [ -z "$BASE_FILES_URL" ]; then
        echo "Error: Could not find base_files_url in db.json!"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    echo "Database base URL: $BASE_FILES_URL"
    
    # Step 4: Extract file paths from "files" object keys
    # JSON format: {"files": {"Wallpapers/file.jpg": {"hash":"...", "size":..., "tags":[...]}}, ...}
    # We need to extract the keys of the "files" object
    grep -oP '"Wallpapers/[^"]*\.(jpg|jpeg|png)"' "${TMP_DIR}/db.json" | \
    tr -d '"' > "${TMP_DIR}/filelist.txt"
    
    if [ ! -s "${TMP_DIR}/filelist.txt" ]; then
        echo "Error: Could not extract file list from db.json!"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Step 5: Blacklist filtering
    if [ "$BLACKLIST" != "" ]; then
        echo "Applying blacklist filter..."
        BLACKLIST_ARRAY=($BLACKLIST)
        for keyword in "${BLACKLIST_ARRAY[@]}"; do
            grep -v "$keyword" "${TMP_DIR}/filelist.txt" > "${TMP_DIR}/filelist_filtered.txt"
            mv "${TMP_DIR}/filelist_filtered.txt" "${TMP_DIR}/filelist.txt"
        done
    fi
    
    # Count total files
    TOTAL_FILES=$(wc -l < "${TMP_DIR}/filelist.txt")
    echo "Found $TOTAL_FILES wallpaper files"
    echo
    
    # Step 6: Download wallpaper files
    echo "Starting wallpaper download..."
    echo
    
    CURRENT=0
    SUCCESS=0
    FAILED=0
    SKIPPED=0
    while IFS= read -r filepath; do
        CURRENT=$((CURRENT + 1))
        
        # Extract filename from path (remove "Wallpapers/" prefix)
        filename=$(basename "$filepath")
        
        # Build download URL: base_files_url + "/" + filepath
        FILE_URL="${BASE_FILES_URL}/${filepath}"
        
        # Check if file already exists and is complete (simple check: file size > 0)
        if [ -f "$filename" ] && [ -s "$filename" ]; then
            echo "[$CURRENT/$TOTAL_FILES] Skipped: $filename"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
        
        echo -n "[$CURRENT/$TOTAL_FILES] Downloading: $filename ... "
        
        # Download file
        HTTP_CODE=$(curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} -L -o "$filename" -w "%{http_code}" "$FILE_URL" 2>/dev/null)
        
        if [ "$HTTP_CODE" == "200" ] && [ -f "$filename" ] && [ -s "$filename" ]; then
            echo "OK"
            SUCCESS=$((SUCCESS + 1))
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $filename" >> "$LOGS_PATH/Wallpaper_Downloads.txt"
        else
            echo "FAILED (HTTP $HTTP_CODE)"
            FAILED=$((FAILED + 1))
            rm -f "$filename" 2>/dev/null
        fi
        
    done < "${TMP_DIR}/filelist.txt"
    
    # Clean up temporary files
    rm -rf "$TMP_DIR"
    
    # Summary
    echo
    echo "================================================================"
    echo "  Download complete!"
    echo "  Total: $TOTAL_FILES | Downloaded: $SUCCESS | Skipped: $SKIPPED | Failed: $FAILED"
    echo "================================================================"
    
    if [ "$FAILED" -gt 0 ]; then
        echo "Warning: $FAILED files failed to download. Check your internet connection and try again."
    fi
    
	sleep 1
    clear 		
}

# Footer Function
Footer(){
clear
echo
echo "================================================================"
echo "                MiSTer CRT Wallpapers are up to date!           "
echo "================================================================"
echo
}

#========= MAIN CODE =========

# Print banner
RetroDriven_Banner

# Create logs directory
LOGS_PATH="/media/fat/Scripts/.RetroDriven/Logs"
mkdir -p "$LOGS_PATH"

# Download wallpapers
Download_Wallpapers

echo

# Display footer
Footer
echo "Wallpapers designed and provided by: Ranny Snice"
echo
echo "Wallpaper collection location: /media/fat/wallpapers"
echo
echo "Script modified by: trees"
echo
