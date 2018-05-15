#!/bin/bash
#
# Convert each article manuscript (in ODT or DOCX) in markdown, and save in "./1-layout/" directory.
# Also archive a backup copy of the results, log all the events and rename converted files
# Please provide the manuscript in "./0-original/"
#
# Author: Piero Grandesso
# Version: 0.9
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

printf "[$(date +"%Y-%m-%d %H:%M:%S")] fulltext-markdown.sh started running, logging events" >> "$workingDir/$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

######
# 1. create directory structure for working and archiving, if not already there
######
mkdir -p $workingDir/{archive/{original-version,first-conversion,editing-ready},1-layout}
# creating only the directories pertaining to this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$workingDir/$eventslog"

# now a temporary folder
tempdir=`mktemp -d $workingDir/tmp.XXXXXXXXXXXX`

# temporary file for storing variables
tempvar=`mktemp $workingDir/tmp-values.XXXXXXXXX.sh`

######
# 2. conversion, change extension, not filename; then archive manuscript
######
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Starting conversion of manuscripts from ./0-original..." >> "$workingDir/$eventslog"
( # start subshell
	if cd ./0-original ; then
		:
	else
		# if "old" original folder...
		if cd ./original ; then
			cd ..
			echo "Moving old ./original to its new name: ./0-original"
			mv ./original ./0-original
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Moving old ./original to its new name: ./0-original." >> "$workingDir/$eventslog"
			cd ./0-original
		else
			echo "WARNING: ./0-original directory not found!"
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./0-original directory not found! Aborting." >> "$workingDir/$eventslog"
			exit 77
		fi
	fi

	EXT1=docx
	EXT2=odt
	# check if there are valid files
	EXT=(`find ./ -maxdepth 1 -regextype posix-extended -regex '.*\.(docx|odt)$'`)
	if [ ${#EXT[@]} -gt 0 ]; then
		: # valid files, ok
	else
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] No valid files found in ./0-original, exiting now" >> "$workingDir/$eventslog"
		echo "WARNING: no valid files!"
		exit 77
	fi

	# convert valid files
	for manuscript in *{docx,odt} ; do
		if [ "${manuscript}" != "${manuscript%.${EXT1}}" ]; then
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript}: trying to convert it in Markdown..." >> "$workingDir/$eventslog"
			# actual conversion with Pandoc
			if pandoc --wrap=none --atx-headers -o "$tempdir/${manuscript%.${EXT1}}.md" "$manuscript" ; then
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ... ${manuscript} was converted!" >> "$workingDir/$eventslog"
				# archive the processed manuscript
				mv "$manuscript" "$workingDir/archive/original-version/${manuscript%.${EXT1}}-$(date +"%Y-%m-%dT%H:%M:%S").${EXT1}"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript} archived" >> "$workingDir/$eventslog"
			else
				# pandoc returned errors, print a warning and don't archive
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ... [WARN] pandoc failed in converting ${manuscript} to Markdown!" >> "$workingDir/$eventslog"
				echo WARN=true >> $tempvar
			fi
		elif [ "${manuscript}" != "${manuscript%.${EXT2}}" ]; then
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript}: trying to convert it in Markdown..." >> "$workingDir/$eventslog"
			# actual conversion with Pandoc
			if pandoc --wrap=none --atx-headers -o "$tempdir/${manuscript%.${EXT2}}.md" "$manuscript" ; then
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ... ${manuscript} was converted!" >> "$workingDir/$eventslog"
				# archive the processed manuscript - TEST: cp instead of mv
				cp "$manuscript" "$workingDir/archive/original-version/${manuscript%.${EXT2}}-$(date +"%Y-%m-%dT%H:%M:%S").${EXT2}"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript} archived" >> "$workingDir/$eventslog"
			else
				# pandoc returned errors, print a warning and don't archive
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ... [WARN] pandoc failed in converting ${manuscript} to Markdown!" >> "$workingDir/$eventslog"
				echo WARN=true >> $tempvar
			fi
		fi
	done
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Original manuscripts are archived in ./archive/original-version with timestamp; something left behind?..." >> "$workingDir/$eventslog"

	# check if any file is left behind in ./0-original
	for manuscript in * .*; do
		[ -f "$manuscript" ] || continue
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] ${manuscript} was skipped (had errors, wrong extension or it is hidden)" >> "$workingDir/$eventslog"
		echo WARN=true >> $tempvar
	done
) # end subshell


######
# 3. rename files
######

shopt -s nullglob # Sets nullglob

( # start subshell
	if cd "$tempdir" ; then
		echo "Starting conversions..."
	else
		echo "WARNING: temporary working directory not found!"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: temporary working directory not found! Aborting." >> "$workingDir/$eventslog"
		exit 77
	fi
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Archiving newly converted manuscripts in ./archive/first-conversion..." >> "$workingDir/$eventslog"
	for oldname in *.md; do
		# copy to archive
		cp "$oldname" "$workingDir/archive/first-conversion/${oldname%.md}-$(date +"%Y-%m-%dT%H:%M:%S").md"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   $oldname archived" >> "$workingDir/$eventslog"
	done

	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Renaming converted manuscripts..." >> "$workingDir/$eventslog"
	# check if files has the correct name with the following regex ("(en|it)" is optional to distinguish multiple galleys
	goodname="([0-9]+-?([a-zA-Z]{2,3})?)-[0-9]+-[0-9]+-[A-Z]{2}\.md"
	for oldname in *.md; do
		if [[ $oldname =~ $goodname ]]; then
			# rename keeping only relevant part and transforming to lowercase
			cleanname=$(echo "$oldname" | sed -r "s/$goodname/\1.md/" | tr "[:upper:]" "[:lower:]")
			mv "$oldname" "$cleanname"
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   $oldname renamed as $cleanname" >> "$workingDir/$eventslog"
		else
			# safer filenames to lowercase and replacing spaces with underscore
			safename=$(echo "$oldname" | sed -r "s/$goodname/\1.md/" | tr "[:upper:]" "[:lower:]" | tr "[:blank:]" "_")
			if [[ $oldname =~ $safename ]]; then
				: # all ok, does nothing
			else
				mv "$oldname" "$safename"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] $oldname has an unexpected name, converted in a safer one!" >> "$workingDir/$eventslog"
				echo WARN=true >> $tempvar
			fi
		fi
	done
	#printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Conversion finished!" >> "$workingDir/$eventslog"


	######
	# 4. Prep manuscripts in Markdown for editing
	######

	# folders for media files
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Creating folders for media files in ./1-layout" >> "$workingDir/$eventslog"
	for f in *.md; do
		fname=$(echo $f | sed -r "s/\.md//")
		if [ ! -d "$workingDir/1-layout/$fname-media" ]; then
			mkdir "$workingDir/1-layout/$fname-media"
		else
			RERUN=true
			#printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ./archive/$dir/ already there" >> "$workingDir/$eventslog"
		fi
	done
	if [ $RERUN ]; then
		echo "NOTICE: some files where already parsed before (or something is wrong!)"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   some folders already there, skipped" >> "$workingDir/$eventslog"
	else
		: # all ok, does nothing
	fi

	# add empty YAML at the start of each article
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Prepending metadata YAML..." >> "$workingDir/$eventslog"
	yaml_file=$workingDir/z-lib/article.yaml
	size=$(wc -c < "$yaml_file")

	for file in *.md; do
		if ( cmp -n "$size" "$yaml_file" "$file" &> /dev/null ); then
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] $file has already YAML" >> "$workingDir/$eventslog"
			echo WARN=true >> $tempvar
		else
			tempfile=$(mktemp)
			cat "$yaml_file" "$file" > "$tempfile"
			mv "$tempfile" "$file"
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   $file has now the empty YAML" >> "$workingDir/$eventslog"
		fi
	done

	# archive editing-ready manuscripts in ./archive/editing-ready
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Manuscripts are ready, archiving to ./archived/editing-ready/ and moving to ./1-layout/..." >> "$workingDir/$eventslog"
	for editing in *.md; do
		cp "$editing" "$workingDir/1-layout/"
		mv "$editing" "$workingDir/archive/editing-ready/${editing%.md}-$(date +"%Y-%m-%dT%H:%M:%S").md"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   $editing is ready" >> "$workingDir/$eventslog"
	done

	# check if any file is left behind in ./$tempdir
	for garbage in * .*; do
		[ -f "$garbage" ] || continue
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] ${garbage} should not be here" >> "$workingDir/$eventslog"
		echo WARN=true >> $tempvar
		echo KEEPDIR=true >> $tempvar
	done
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Manuscripts are processed and ready for editing in ./1-layout; each step has been archived with timestamp in ./archive" >> "$workingDir/$eventslog"

) # end subshell

shopt -u nullglob # Unsets nullglob

# variable check
. $tempvar

# send a message if a problem occurred
if [ $WARN ]; then
	echo "WARNING: please check the events log"
else
	: # all ok, does nothing
fi

if [ $KEEPDIR ]; then
	echo "WARNING: the temporary directory won't be deleted, check log!"
	rm $tempvar
else
	rm $tempvar
	rm -d $tempdir
fi

echo "All files are in ./1-layout, ready for editing. Each stage of the process has been logged and archived"
