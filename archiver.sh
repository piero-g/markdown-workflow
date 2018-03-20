#!/bin/bash
#
# Archive the working directory, creating also a "self-contained" version of layout files, with issue and journal settings appended
#
# Author: Piero Grandesso
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
printf "[$(date +"%Y-%m-%d %H:%M:%S")] archive.sh started running, logging events" >> "$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p ./archive/{media,final-version/{z-lib,self-contained,publication}}
# creating only the directories pertaining this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$eventslog"

# now a temporary folder
tempdir=`mktemp -d ./tmp.XXXXXXXXXXXX`

######
# 2. preparing "self-contained" layout files
######

echo "Preparing \"self contained\" layout files"
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Copying layout files to a temporary directory" >> "$eventslog"
cp -a ./1-layout/*.md ./$tempdir/

( # start subshell
	cd ./$tempdir/
	for layout in *.md ; do
		cat "../z-lib/issue.yaml" >> ${layout}
		wait
		cat "../z-lib/journal.yaml" >> ${layout}
		wait
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Issue and journal settings appended to ${layout}, now archiving" >> "../$eventslog"
		mv ${layout} ../archive/final-version/self-contained/${layout}
	done
) # end subshell

######
# 3. archive everything
######

# publication directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving publication files..." >> "$eventslog"
( # start subshell
	cd ./2-publication/
	for galley in *.{pdf,html,xml,tex} ; do
		# TEST: change with mv
		mv ${galley} -t ../archive/final-version/publication/
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\t...publication file ${galley} archived" >> "../$eventslog"
	done
) # end subshell

# layout directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving layout files..." >> "$eventslog"
( # start subshell
	cd ./1-layout/
	for layout in *.md ; do
		# TEST: change with mv
		mv ${layout} -t ../archive/final-version/
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\t...final version of layout file for ${layout%.md} archived" >> "../$eventslog"
	done
) # end subshell

# z-lib directory
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving ./z-lib/ folder" >> "$eventslog"
cp -a ./z-lib/* ./archive/final-version/z-lib/

# media directories
if [ ! -d ./1-layout/*-media ] ; then
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] No media directories found in layout" >> "$eventslog"
else
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving media folders" >> "$eventslog"
	mv ./1-layout/*-media -t ./archive/media/
fi

printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving scripts" >> "$eventslog"
# copy the current scripts
cp -a {img-compress,fulltext-markdown,markdown-galleys}.sh -t ./archive/

# check if any file is left behind in ./$tempdir
( # start subshell
cd ./$tempdir
	for garbage in * .*; do
		[ -f "$garbage" ] || continue
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\t[WARN] ${garbage} should not be here" >> "../$eventslog"
		KEEPDIR=true
	done
	if [ $KEEPDIR ]; then
		echo "WARNING: the temporary directory won't be deleted, something is wrong!"
	else
		cd ..
		rm -d $tempdir
	fi
) # end subshell


######
# 4. finalize archive
######
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] This log is going into the archive too, bye bye!" >> "$eventslog"
mv $eventslog -t ./archive/

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
