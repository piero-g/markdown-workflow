#!/bin/bash
#
# YAML mass edit?
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
printf "[$(date +"%Y-%m-%d %H:%M:%S")] serial-editor.sh started running, logging events" >> "$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

# set the current working directory for future cd
workingDir=$PWD

# temporary file for storing variables
tempvar=`mktemp $workingDir/tmp-values.XXXXXXXXX.sh`

# reading options with getopt...
getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

OPTIONS=up:cs:
LONGOPTIONS=undraft,publication:,countpages,pagesequence:

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

printf "[$(date +"%Y-%m-%d %H:%M:%S")] current command options: $PARSED\n" >> "$eventslog"

if [[ $? -ne 0 ]]; then
	# e.g. $? == 1
	#  then getopt has complained about wrong arguments to stdout
	exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
	case "$1" in
		-u|--undraft)
			u=y
			shift
			;;
		-p|--publication)
			publicationDate="$2"
			shift 2
			;;
		-c|--countpages)
			pageCount=y
			shift
			;;
		-s|--pagesequence)
			pageSequence="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Programming error"
			exit 3
			;;
	esac
done

# countpages and pageSequence are exclusive options (and countpages prevails)
if ([ $u ] || [ $publicationDate ] || [ $pageSequence ]) && [ $pageCount ]; then
	echo -e "WARNING: Page count is requested, any other option will be ignored!\n"
else
	if ([ $u ] || [ $publicationDate ]) && [ $pageSequence ]; then
		echo -e "WARNING: A pageSequence is selected: any other option will be ignored!\n"
	else
		:
	fi
fi


######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p ./archive/layout-versions
# creating only the directories pertaining this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$eventslog"

######
# 2. conversion, change extension, not filename; then archive manuscript
######

# prepare daily subdirectory for layout-versions archiving
mkdir -p ./archive/layout-versions/$today

# undraft
undraft() {
	sed -r -i.undraft.bak '0,/^(draft:)\s+true *#?(.*)$/s//\1 false #\2/' "${manuscript}"
	diff "${manuscript}" "${manuscript}.undraft.bak"
}

# set publication date
setpubdate() {
	echo "$publicationDate"
	#echo sed -r -i.pub.bak "0,/^\s+(published:)\s+\d\d\d\d\-\d\d\-\d\d/s//\1 $publicationDate/" "${manuscript}"
	sed -r -i.pub.bak -e '0,/^(\s+published:)\s+[0-9]{4}-[0-9]{2}-[0-9]{2} *#?(.*)$/s//\1 '$publicationDate' #\2/' "${manuscript}"
	diff "${manuscript}" "${manuscript}.pub.bak"
}

# editing function
edityaml() {

	echo -e "\n\tediting YAML in ${manuscript%.md}..."
	# archive a copy before editing the manuscript
	cp "$manuscript" "$workingDir/archive/layout-versions/$today/${manuscript%.md}-$(date +"%Y-%m-%dT%H:%M:%S").md"
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   copy of ${manuscript%.md} archived" >> "$workingDir/$eventslog"

	if [ $u ]; then
		undraft
	fi

	if [ $publicationDate ]; then
		setpubdate
	fi
}

# Do you want to run editing on a specific article?
if [ -z ${@+x} ]; then
	# no file specified, run on each file within the directory
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Starting editing of manuscripts in ./1-layout..." >> "$eventslog"
	# also store a flag
	echo ALL=true >> $tempvar
	( # start subshell
		if cd ./1-layout ; then
			echo "Starting editing..."
		else
			echo "WARNING: ./1-layout directory not found!"
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$eventslog"
			exit 77
		fi

		# check if there are valid files
		EXT=(`find ./ -maxdepth 1 -regextype posix-extended -regex '.*\.(md)$'`)
		if [ ${#EXT[@]} -gt 0 ]; then
			: # valid files, ok
		else
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] No valid files found in ./1-layout, exiting now" >> "../$eventslog"
			echo "WARNING: no valid files!"
			exit 77
		fi

		if [ $pageCount ] || [ $pageSequence ]; then
			: # skip edityaml
		else
			# convert valid files
			for markdown in ./*.md; do

				manuscript="${markdown#.\/}"
				# launch editing
				edityaml

			done
		fi
	) # end subshell

else # we have a parameter: convert only specified file

	if [ $pageCount ] || [ $pageSequence ]; then
		echo "WARNING: the option selected won't run on specific files, aborting!"
		exit 1
	fi
	for parameter in $@; do

		manuscript="$( echo "$parameter" | sed -r 's/^\.?\/?1\-layout\///' )"

		if [[ $manuscript == *.md ]]; then
			: # valid files, ok
		else
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] The specified $manuscript has not a valid extension, exiting now" >> "$eventslog"
			echo "WARNING: $manuscript is not valid!"
			exit 1
		fi

		( # start subshell
			if cd ./1-layout ; then
				echo "Starting editing..."
			else
				echo "WARNING: ./1-layout directory not found!"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$eventslog"
				exit 77
			fi

			edityaml

		) # end subshell
	done


fi

###
# COUNTING FUNCTION
# page counter, it will only count pages of PDF on the entire "2-publication" folder
###
countpages() {
	echo -e "\nnumber of pages for ${manuscript}..."
	# actual conversion with Pandoc
	pdfinfo "${manuscript}" | grep Pages
}

if [ $pageCount ]; then
	# do not run setpage on a single file (variable check)
	. $tempvar
	if [ $ALL ]; then
		# no file specified, proceed
		( # start subshell
			if cd ./2-publication ; then
				for manuscript in *pdf ; do
					# counter function
					countpages
				done
			else
				echo "WARNING: ./2-publication directory not found!"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./2-publication directory not found! Aborting." >> "$eventslog"
				exit 77
			fi
		) # end subshell
	else
		echo "WARNING: the page sequence can only be applied to the full issue, I will exit"
		exit 1
	fi

	# countpages has priority, so we have to exit now
	# remove working files
	rm $tempvar
	exit 1
else
	:
fi


###
# PAGE SEQUENCE
# page sequence, it will run on the entire "1-layout" folder
###

setstartpage() {
	sed -r -i.start.bak -e '0,/^(\s+start:)\s+[0-9] *#?(.*)$/s//\1 '${arry[1]}' #\2/' ${arry[0]}
	diff ${arry[0]} ${arry[0]}.start.bak
}
setendpage() {
	sed -r -i.end.bak -e '0,/^(\s+end:)\s+[0-9] *#?(.*)$/s//\1 '${arry[2]}' #\2/' ${arry[0]}
	diff ${arry[0]} ${arry[0]}.end.bak
}

# parse TSV and take care for correct paring of file name and values
parsepages() {
	echo "set page ${pageSequence}!"
	# parse TSV
	sed 1d ${pageSequence} | while IFS=$'\t' read -r -a arry
	do
		echo -e "\n" ${arry[0]} "is the filename..."
		echo "..." ${arry[1]} "is its startPage"
		echo "..." ${arry[2]} "is its endPage"
		( # start subshell
			if cd ./1-layout ; then
				:
			else
				echo "WARNING: ./1-layout directory not found!"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$eventslog"
				exit 77
			fi
			if [[ -f ${arry[0]} ]] && [[ ${arry[0]} == *.md ]]; then
				# we have the file, proceed
				setstartpage
				setendpage
			else
				echo "Warning:" ${arry[0]} "not found, skipping!"
			fi
		) # end subshell
		sleep 2
	done


}

# check input source if pageSequence
if [ $pageSequence ]; then
	# do not run setpage on a single file (variable check)
	. $tempvar
	if [ $ALL ]; then
		# no file specified, proceed
		# check that the input is a TSV
		if [[ (-f ${pageSequence}) && (${pageSequence} == *.tsv) ]]; then
			echo "ok, it's a TSV!"
			parsepages
		else
			echo "I can't find a file named ${pageSequence} or its not a TSV, abort!"
			exit 1
		fi
	else
		echo "WARNING: the page sequence can only be applied to the full issue, I will exit"
		exit 1
	fi
else
	:
fi

# remove working files
rm $tempvar
# we should remove also .bak files


echo "We are done here!"
