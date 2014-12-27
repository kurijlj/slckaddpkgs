#!/bin/bash
#
# slckaddpkgs.sh - Manages dependencies and retrieval of various software
#                  packages
# Copyright (C) 2014  Ljubomir Kurij
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
###############################################################################
# Script : /usr/local/bin/slckaddpkgs.sh
# Purpose: Simple system for managing dependencies and retrieval of various
#          unofficial software packages for Slackware.
# Author : Ljubomir Kurij <kurijlj@gmail.com>
#          System is built on top of the SlackBuilds.org build scripts. It uses
#          simple text configuration file to store all dependencies and
#          information about packages (packages.cfg), located in
#          ${HOME}/.slckaddpkgs. So far this configuration file must be
#          populated manually. After each retrieval information on downloaded
#          packages is stored into downloads.log file, located in
#          ${HOME}/.slckaddpkgs.
# Version: 1.0
###############################################################################
# Usage..: slckaddpkgs.sh [-b|-g|-l|-i|-m|-h|-v] <PACKAGE_NAME>\
#                         <categories | packages | CATEGORY_NAME | PACKAGE_NAME>
#          Run slckaddpkgs.sh -h for more information.
###############################################################################
# History #
###########
# v1.00 - 01/31/2014
#       * Created
###############################################################################




# Get the configuration information from ${HOME}/.slckaddpkgs/slckaddpkgsrc:
. "${HOME}"/.slckaddpkgs/slckaddpkgsrc




###############################################################################
# Functions declaration space begins here
#

# Function to test if given character stream belongs to categories, packages or
# neither
function corpexist () {
	for rs in $(egrep -i "^.+\.category:" "$CF");do
		if [[ "packagename.category:" != "$rs" ]]; then

			# Test if category
			[[ $(cut -d":" -f2- <<< "$rs") = "${1}" ]] && return 1

			# Test if package
			[[ $(cut -d"." -f1 <<< "$rs") = "${1}" ]] && return 2

		fi

	done

	return 0

}




# Function to print all existing package categories
function print_ctgs {
	egrep -i "^.+\.category:" "$CF" | \
		cut -d":" -f2- | \
		sort | \
		uniq | \
		while read ctg; do
		[[ "" != "$ctg" ]] && echo -e "$ctg" >&2

	done
}




# Function to print all existing major and supplementary packages
function print_pkgs () {
	egrep -i "^.+\.major:.+$" "$CF" | sort | while read mline; do
		pkg=$(cut -d"." -f1 <<< "$mline")
		mjr=$(cut -d":" -f2 <<< "$mline")

		if [[ "package-framework" != "$pkg" ]]; then
			case $1 in
				# If "inline" option set print all packages in
				# one line
				i)
					printf "%s " "$pkg"
					;;
				# If "major" option set print just major
				# packages
				m)
					[[ "true" = "$mjr" ]] && \
						echo -e "$pkg" >&2
					;;
				# else print all packages line by line
				*)
					echo -e "$pkg" >&2
					;;
			esac

		fi

	done
}




# Function to print category details
function print_ctg () {
	pkgs=$(egrep -i "^.+\.category:${1}$" "$CF" | cut -d"." -f1)

	echo -e "***** $1 *****" >&2
	echo -e "" >&2

	# If brief option is set just print packages name else print
	# full description
	[[ "b" = "$2" ]] && \
		echo -e "$pkgs" >&2 || \
		while read pkg; do print_pkg "$pkg"; done <<< "$pkgs"
}




# Function to print package details
function print_pkg () {
	# Fill in package data
	pkg="$1"
	pkgblk=$(egrep -i "^${pkg}\." "$CF")
	ctg=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.category" | cut -d":" -f2-)
	ver=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.version" | cut -d":" -f2)
	desc=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.description:" | cut -d":" -f2-)
	srcs=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.source:" | cut -d":" -f2-)
	bld=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.slackbuild:" | cut -d":" -f2-)
	req=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.requires:" | cut -d":" -f2-)
	news=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.news:" | cut -d":" -f2-)

	# If brief option is set just print package name
	if [[ "b" = "$2" ]]; then
		echo -e "$pkg" >&2

	# else print full package data
	else
		echo -e "- $pkg -" >&2

		# Get package description form SlackBuilds.org
		rs=$(wget -q "$desc" -O - 2>&1); rc=$?
		[[ 0 -eq $rc ]] && echo -e "$rs" >&2 || echo -e "N/A" >&2

		echo -e "" >&2
		echo -e "category: $ctg" >&2
		echo -e "version: $ver" >&2

		# Print all the sources properly
		while read src; do
			echo -e "source: $(cut -d" " -f2 <<< "$src")" >&2
		done <<< "$srcs"

		echo -e "slackbuild: $bld" >&2
		echo -e "requires: $req" >&2
		echo -e "news: $news" >&2
		echo -e "" >&2
	fi

	# If package depends on other packages print them too
	if [[ "none" != "$req" ]]; then
		for preq in $req; do
			[[ "b" = "$2" ]] && \
				print_pkg "$preq" "b" || \
				print_pkg "$preq"

		done

	fi

}




function get_pkg () {
	# Fill in package data
	pkg=$1
	pkgblk=$(egrep -i "^${pkg}\." "$CF")
	srcs=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.source:" | cut -d":" -f2-)
	bld=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.slackbuild:" | cut -d":" -f2-)
	req=$(echo -e "$pkgblk" | \
		egrep -i "^${pkg}\.requires:" | cut -d":" -f2-)

	# Check if logfile directory exists else create it
	[[ ! -d $LFDIR ]] && mkdir -p "$LFDIR"

	echo -e "- Retrieving package \"${pkg}\" -" >&2
	echo -e "" >&2
	echo -e "Retrieving slackbuild file ..." >&2

	# Clear previous download
	rm -rf ./"$(cut -d"/" -f7- <<< "$bld")"

	# Try to download slackbuild package
	wget -nv "$bld" &>> $LF

	# Check if download was successfull, else bail out
	rc=$?
	if [[ ! 0 -eq $rc ]]; then
		echo -e "Error downloading from: $bld"
		exit 1
	fi
	
	# Download properly all source files
	while read src; do
		sfname=$(cut -d" " -f1 <<< "$src")
		sflink=$(cut -d" " -f2 <<< "$src")
		echo -e "Retrieving source file \"${sfname}\" ..." >&2

		# Try to download current source file
		wget -nv "$sflink" -O ./"$sfname" &>> $LF

		# Check if download was successfull, else bail out
		if [[ ! 0 -eq $? ]]; then
			echo -e "Error downloading from: $sflink"
			exit 1
		fi

	done <<< "$srcs"


	# Slackbuild and source file are downloaded so lets try to extract
	# and copy them to /tmp directory
	echo -e "Extracting slackbuild file ..." >&2

	# Store pwd so we can return later
	cwd=$(pwd)

	cd "$TMP"

	# Clear previous extraction
	rm -rf ./"$pkg"
	tar -xzf "$cwd"/$(cut -d"/" -f7- <<< "$bld")
	cd ./$(cut -d"/" -f7- <<< "$bld" | cut -d"." -f1)

	while read src; do
		sfname=$(cut -d" " -f1 <<< "$src")
		echo -e "Moving source file \"${sfname}\" ..." >&2
		mv "$cwd"/"$sfname" ./
	done <<< "$srcs"

	# Go to starting directory
	cd "$cwd"

	echo -e "" >&2

	# If package depends on other packages get them too
	if [[ "none" != "$req" ]]; then
		for preq in $req; do get_pkg "$preq"; done
	fi

}




function print_na {
	echo -e "No such category/package!" >&2
	echo -e "Use slckaddpkgs.sh -<m>l <categories/packages> for complete list" >&2
	echo -e "of categories/packages." >&2
	echo -e "" >&2
}




function print_usage {
	echo -e "Usage: generic_getopt.sh [OPTION]" >&2
	echo -e "" >&2
	echo -e "    -b                                     with -l, print brief lists" >&2
	echo -e "" >&2
	echo -e "    -g [PACKAGE_NAME]                      get packages to install" >&2
	echo -e "                                           according to given parameter" >&2
	echo -e "" >&2
	echo -e "    -l [categories | packages |            print list according" >&2
	echo -e "        | CATEGORY_NAME | PACKAGE_NAME]    to given parameter" >&2
	echo -e "" >&2
	echo -e "    -i                                     with \"-l packages\" print brief" >&2
	echo -e "                                           list in one line" >&2
	echo -e "" >&2
	echo -e "    -m                                     with \"-l packages\" print major" >&2
	echo -e "                                           packages list. This flag is exclusive" >&2
	echo -e "                                           with -i flag" >&2
	echo -e "" >&2
	echo -e "    -h                                     give this help list" >&2
	echo -e "" >&2
	echo -e "Report bugs to kurijlj@gmail.com." >&2
	echo -e "" >&2
}




function print_version {
	echo -e "slckaddpkgs.sh 1.0 Copyright (C) 2014 Ljubomir Kurij." >&2
	echo -e "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>" >&2
	echo -e "This is free software: you are free to change and redistribute it." >&2
	echo -e "There is NO WARRANTY, to the extent permitted by law." >&2
	echo -e "" >&2
}




###############################################################################
# Main script's body begins here
#

BFL=0	# Brief flag
GFL=0	# Get flag
IFL=0	# Inline flag
DCSFL=0	# Display all categories flag
DCFL=0	# Display category info flag
DPSFL=0	# Display all major and supplementary packages flag
DPFL=0	# Display package info flag
MFL=0	# Display only major packages flag
ARG=""	# Argument holding space

# Check if any optin supplied, else print usage and bail out
[[ 0 = $# ]] && print_usage && exit 1

while getopts ":bg:l:imhv" opt; do
	case "$opt" in
		b)
			let BFL=1
			;;
		g)
			rc=$(corpexist "$OPTARG")$?
			case "$rc" in
				2)
					let GFL=1
					ARG="$OPTARG"
					;;
				*)
					print_na
					exit 1
					;;
			esac
			;;
		i)
			let IFL=1
			;;
		m)
			let MFL=1
			;;
		l)
			case "$OPTARG" in
				categories)
					let DCSFL=1
					;;
				packages)
					let DPSFL=1
					;;
				*)
					rc=$(corpexist "$OPTARG")$?
					case "$rc" in
						0)
							print_na
							exit 1
							;;
						1)
							let DCFL=1
							ARG="$OPTARG"
							;;
						2)
							let DPFL=1
							ARG="$OPTARG"
							;;
					esac
					;;
			esac
			;;
		h)
			print_usage
			;;
		v)
			print_version
			;;
		*)
			print_usage
			exit 1
			;;
	esac
done

if [[ 1 -eq $BFL ]]; then
	if [[ 1 -eq $DCFL ]]; then
		print_ctg "$ARG" "b"
		echo -e "" >&2

	elif [[ 1 -eq $DPFL ]]; then
		print_pkg "$ARG" "b"
		echo -e "" >&2

	else
		print_usage
		exit 1

	fi

elif [[ 1 -eq $DCFL ]]; then
	print_ctg "$ARG"
	echo -e "" >&2

elif [[ 1 -eq $DPFL ]]; then
	print_pkg "$ARG"
	echo -e "" >&2

elif [[ 1 -eq $DCSFL ]]; then
	print_ctgs
	echo -e "" >&2

elif [[ 1 -eq $IFL ]]; then
	if [[ 1 -eq $DPSFL ]]; then
		print_pkgs "i"

	else
		print_usage
		exit 1

	fi

elif [[ 1 -eq $MFL ]]; then
	if [[ 1 -eq $DPSFL ]]; then
		print_pkgs "m"
		echo -e "" >&2

	else
		print_usage
		exit 1

	fi

elif [[ 1 -eq $DPSFL ]]; then
	print_pkgs
	echo -e "" >&2

elif [[ 1 -eq $GFL ]]; then
	get_pkg "$ARG"

fi

exit 0
