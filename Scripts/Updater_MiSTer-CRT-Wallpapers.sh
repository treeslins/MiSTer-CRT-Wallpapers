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

# Copyright 2020 - Treeslins and Ranny Snice

# You can download the latest version of this script from:
# https://github.com/Treeslins/MiSTer-CRT-Wallpapers

# v1.0 - Initial MiSTer-CRT-Wallpapers Script

#=========   URL OPTIONS   =========

#Main URL
MAIN_URL="https://treeslins.com"

#=========   USER OPTIONS   =========

#Choose if you'd like to manage the Wallpapers that appear on your MiSTer Menu
#Set to "False" if you'd like your MiSTer to randomly select a Wallpaper from everything downloaded
#Set to "True" if you'd like top manually manage/copy from /wallpapers/subfolders to /wallpapers 
SELF_MANAGED="False"

#Case Sensitive Keywords to Skip Downloading Wallpapers that you do not want
#NOTE: The list is separated by space so only use part of the word if it's more than one word
#EXAMPLE: BLACKLIST="Powerpuff Bowsette Vampire"
BLACKLIST=""

#========= FUNCTIONS =========

# Terminal width and padding helpers
INNER_W=60
TERM_W=$(tput cols 2>/dev/null || echo 80)
PAD=$(( (TERM_W - INNER_W) / 2 ))
[ $PAD -lt 0 ] && PAD=0
SP=$(printf "%${PAD}s" "")

# Print a separator line (centered)
print_line(){
	echo "${SP}$(printf '%0.s=' $(seq 1 $INNER_W))"
}

# Print centered text (no side borders)
print_center(){
	local text="$1"
	local len=${#text}
	local lp=$(( (INNER_W - len) / 2 ))
	printf "%s%*s%s\n" "$SP" $lp "" "$text"
}

#Treeslins Updater Banner Function
Treeslins_Banner(){
echo

# Banner uses bordered box
bcnt(){
	local text="$1"
	local len=${#text}
	local lp=$(( (INNER_W - 2 - len) / 2 ))
	local rp=$(( INNER_W - 2 - len - lp ))
	printf "%s|%*s%s%*s|\n" "$SP" $lp "" "$text" $rp ""
}

echo "${SP}$(printf '%0.s-' $(seq 1 $INNER_W))"
bcnt "MiSTer CRT Wallpapers v1.0"
bcnt "powered by Treeslins"
echo "${SP}$(printf '%0.s-' $(seq 1 $INNER_W))"

sleep 3

}

#Setup Directories and Menu Files
Setup_Wallpapers(){

    echo
    print_line
    print_center "Setting Up MiSTer CRT Wallpapers"
    print_line
	sleep 1

	#Make Directories if needed
	mkdir -p "/media/fat/wallpapers"

	#Rename and move menu.jpg/png in root
	if [ -f /media/fat/menu.jpg ]; then
		mv -f "/media/fat/menu.jpg" "/media/fat/wallpapers/menu2.jpg" 2>/dev/null
	fi

	if [ -f /media/fat/menu.png ]; then
		mv -f "/media/fat/menu.png" "/media/fat/wallpapers/menu2.png" 2>/dev/null
	fi

	sleep 1
    clear
}

#Footer Function
Footer(){
clear
echo
print_line
print_center "MiSTer CRT Wallpapers are up to date!"
print_line
echo

}

#========= MAIN CODE =========

#Treeslins Updater Banner
Treeslins_Banner

#Setup Wallpapers
Setup_Wallpapers

echo

#Display Footer
Footer
echo "Wallpapers designed and provided by: Ranny Snice"
echo
echo "Wallpaper Collection located here: /media/fat/wallpapers"
