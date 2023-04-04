#!/bin/bash
#
# Archive the working directory, creating also a "self-contained" version of layout files, with issue and journal settings appended
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
	# set the current working directory for future cd
	workingDir="$PWD"
else
	echo "Something went wrong with event logger, aborting! (is ./z-lib/ in its place?)"
	exit 1
fi
printf "[$(date +"%Y-%m-%d %H:%M:%S")] archive.sh started running, logging events" >> "$workingDir/$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p ./archive/{media,final-version/{z-lib,self-contained,publication}}
# creating only the directories pertaining this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$workingDir/$eventslog"

# now a temporary folder
tempdir=`mktemp -d "$workingDir/tmp.XXXXXXXXXXXX"`

######
# 2. preparing "self-contained" layout files
######

echo "Preparing \"self contained\" layout files"
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Copying layout files to a temporary directory" >> "$workingDir/$eventslog"
cp -a "$workingDir/1-layout/"*.md "$tempdir"

( # start subshell
	cd "$tempdir"
	for layout in *.md ; do
		printf "\n\n" >> "${layout}"
		cat "$workingDir/z-lib/issue.yaml" >> "${layout}"
		wait
		cat "$workingDir/z-lib/journal.yaml" >> "${layout}"
		wait
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Issue and journal settings appended to ${layout}, now archiving" >> "$workingDir/$eventslog"
		mv "${layout}" "$workingDir/archive/final-version/self-contained/${layout}"
	done
) # end subshell

######
# 3. archive everything
######

# publication directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving publication files..." >> "$workingDir/$eventslog"
( # start subshell
	cd "$workingDir/2-publication/"
	for galley in *.{pdf,html,xml,tex} ; do
		mv "${galley}" -t "$workingDir/archive/final-version/publication/"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ...publication file ${galley} archived" >> "$workingDir/$eventslog"
	done
) # end subshell

# layout directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving layout files..." >> "$workingDir/$eventslog"
( # start subshell
	cd "$workingDir/1-layout/"
	for layout in *.md ; do
		mv "${layout}" -t "$workingDir/archive/final-version/"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ...final version of layout file for ${layout%.md} archived" >> "$workingDir/$eventslog"
	done
) # end subshell

# z-lib directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving ./z-lib/ folder" >> "$workingDir/$eventslog"
cp -a "$workingDir/z-lib/"* "$workingDir/archive/final-version/z-lib/"

# media directories
if [ ! -d "$workingDir/1-layout/"*{-,_}media ] ; then
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] No media directories found in layout" >> "$workingDir/$eventslog"
else
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving media folders" >> "$workingDir/$eventslog"
	mv "$workingDir/1-layout/"*-media -t "$workingDir/archive/media/"
fi

printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving scripts" >> "$workingDir/$eventslog"
# copy the current scripts
cp -a {img-compress,fulltext-markdown,markdown-galleys,serial-editor,status}.sh -t "$workingDir/archive/"

# check if any file is left behind in ./$tempdir
( # start subshell
cd "$tempdir"
	for garbage in * .*; do
		[ -f "$garbage" ] || continue
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] ${garbage} should not be here" >> "$workingDir/$eventslog"
		KEEPDIR=true
	done
	if [ $KEEPDIR ]; then
		echo "WARNING: the temporary directory won't be deleted, something is wrong!"
	else
		cd ..
		rm -d "$tempdir"
	fi
) # end subshell


######
# 4. finalize archive
######
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] This log is going into the archive too, bye bye!" >> "$workingDir/$eventslog"
mv $eventslog -t "$workingDir/archive/"

echo "Working directory should be clean"
echo "Please, check for anything left over and if needed put it into the ./archive folder!"
echo
sleep 5
# now waiting for user input and zipping the archive, with a meaningful identifier
while :
	do
	echo -n "Are you ready to zip the archive? (Y or N) "
	read answer
	if echo "$answer" | grep -iq "^[yY]$" ; then
		while :
		do
			echo -n "Please type a meaningful identifier for the archived articles: "
			read identifier
			echo "The archive name will be \"${identifier}-$today.zip\", confirm? (Y or N) "
			read confirm
			if echo "$confirm" | grep -iq "^[yY]$" ; then
				echo "Now zipping!"
				if zip -r "${identifier}-$today.zip" ./archive/* ; then
					echo "Done! Check ${identifier}-$today.zip; you can now clean everything."
				else
					echo "OH NO! I was unable to zip everything, you should do it by yourself."
				fi
				exit
			else
				:
			fi
		done
	else
		echo "Do you want to zip the archive by yourself, later? (Y or N) "
		read confirm
		if echo "$confirm" | grep -iq "^[yY]$" ; then
			echo "Leaving the archive as is, bye bye!"
			exit
		else
			:
		fi
	fi
done
