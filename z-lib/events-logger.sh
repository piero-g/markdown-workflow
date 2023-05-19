#!/bin/bash
#
# A single script meant to be invoked by other scripts.
# It is used to:
# - check if scripts are exec in the workingDirectory
# - load config (if any)
# - backup the whole workingDirectory (if set)
# - manage daily events.log
#
# Author: Piero Grandesso
# https://github.com/piero-g/markdown-workflow
#
#####
# config file
#####
# if config exists, than load it and execute the daily backup
if [ -e './z-lib/journal.conf' ]; then
	configfile='./z-lib/journal.conf'
	# check if the file is clean
	if egrep -q -v '^#|^[a-z0-9_]*=[A-Za-z0-9/]*$' "$configfile"; then
		echo "Config file is unclean! Check ./z-lib/journal.conf before running me again"
		echo "Exiting now"
		exit 1
	else
		source "$configfile"
		[ -z "$journal_shortname" ] && \
			echo "Journal shortname not set, daily backup of the working directory won't be run"
		[ -z "${backup_path}" ] && \
			echo "Backup path not set, daily backup of the working directory won't be run"
	fi
else
	echo "config file not found, no daily backup of the working directory (see readme)"
	NOCONFIG=true
fi

#####
# events log
#####
today=$(date +"%Y-%m-%d")
eventslog="$today-events.log"

if [ ! -e "$eventslog" ]; then
	for oldlog in *-events.log; do
		## Check if the glob gets expanded to existing files.
		## If not, oldlog here will be exactly the pattern above
		## and the exists test will evaluate to false.
		[ -e "$oldlog" ] && echo "Old logs do exist, archiving" && mv *-events.log ./archive/ || :
		## This is all we needed to know, so we can break after the first iteration
		break
	done

	if [ $NOCONFIG ] || [ -z "${backup_path}" ] || [ -z "$journal_shortname" ]; then
		:
	else
		# incremental backup of the whole working directory outside the synced directory
		echo "Running daily backup of the working directory..."
		rsync -av ./ "${backup_path%/}/$journal_shortname/$today/"
		printf '%b\n' "backup\t$(date +"%Y-%m-%d %H:%M:%S")" >> ${backup_path%/}/$journal_shortname-backup.log
	fi

	touch "$eventslog" && echo "Creating today's events log"
else
	echo "Today's events log does exist"
	printf '%b\n' "\n######\n" >> "$eventslog" # add separator
fi
