#!/bin/bash
#
# Quick status check of the working directory
#
# Author: Piero Grandesso
# https://github.com/piero-g/markdown-workflow
#

#####
# 0. events log and other checks
#####
# also: am I in the right place? (is there z-lib folder?)
if . ./z-lib/events-logger.sh ; then
	echo "Starting events registration in $eventslog"
else
	echo "Something went wrong with event logger, aborting! (is ./z-lib/ in its place?)"
	exit 1
fi
printf "[$(date +"%Y-%m-%d %H:%M:%S")] status.sh started running, logging events" >> "$eventslog"


echo "Checking working directory status..."

#####
# 1. print status on working directories
#####
# 0-original
echo -e "\n\n######\n"
if [ -d 0-original ]; then
	if [[ $(ls -A 0-original) ]]; then
		echo "content of 0-original:"
		echo
		# print list of files
		ls -AgGht 0-original | cut -d ' ' -f 3-
	else
		echo "0-original is empty"
	fi
else
	echo "0-original not found"
fi

# 1-layout
echo -e "\n\n######\n"
if [ -d 1-layout ]; then
	if [[ $(ls -A 1-layout) ]]; then
		echo -e "content of 1-layout (media directories first):"
		echo
		# print list of directories
		ls -AgGhtd 1-layout/*/ | cut -d ' ' -f 4-
		# print list of MD files
		ls -AgGht 1-layout/*.md | cut -d ' ' -f 3-
	else
		echo "1-layout is empty"
	fi
else
	echo "1-layout not found"
fi

# 2-publication
echo -e "\n\n######\n"
if [ -d 2-publication ]; then
	if [[ $(ls -A 2-publication) ]]; then
		echo "last two generated PDF:"
		echo
		# print only the two most recent PDF
		ls -AgGht 2-publication/*.pdf | cut -d ' ' -f 3- | head -n 2
	else
		echo "2-publication is empty"
	fi
else
	echo "2-publication not found"
fi
