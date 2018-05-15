#!/bin/bash
#
# Convert each article from markdown ("./1-layout/" directory) to the final publication files (galleys), and save in "./2-publication/" directory. Al the events are logged.
# Also archive a backup copy of the markdown version and log all the events
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
printf "[$(date +"%Y-%m-%d %H:%M:%S")] markdown-galleys.sh started running, logging events" >> "$workingDir/$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR


######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p $workingDir/{archive/layout-versions,2-publication}
# creating only the directories pertaining this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$workingDir/$eventslog"


######
# 2. conversion, change extension, not filename; then archive manuscript
######

# prepare daily subdirectory for layout-versions archiving
mkdir -p $workingDir/archive/layout-versions/$today

# conversion functions
converttohtml() {
	# HTML conversion with Pandoc  --self-contained
	pandoc "${manuscript}" "$workingDir/z-lib/issue.yaml" "$workingDir/z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --email-obfuscation=references --section-divs --self-contained --template="$workingDir/z-lib/article.html5" --write=html5 --default-image-extension=.low.jpg -o "$workingDir/2-publication/${manuscript%.md}.html"
}
converttopdf() {
	# PDF conversion with Pandoc # -N --toc
	pandoc "${manuscript}" "$workingDir/z-lib/issue.yaml" "$workingDir/z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="$workingDir/z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.pdf"
	# LaTeX
	pandoc "${manuscript}" "$workingDir/z-lib/issue.yaml" "$workingDir/z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="$workingDir/z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.tex"
}
converttoxml() {
	# JATS XML
	pandoc "${manuscript}" "$workingDir/z-lib/issue.yaml" "$workingDir/z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="$workingDir/z-lib/article.jats" --write=jats --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.jats.xml"
	# TEI XML
	#pandoc "${manuscript}" "$workingDir/z-lib/issue.yaml" "$workingDir/z-lib/journal.yaml" --toc -N --filter=pandoc-citeproc --template="$workingDir/z-lib/article.tei" --write=tei -s -o "$workingDir/2-publication/${manuscript%.md}.tei.xml"
}

# generic function that calls the specific conversions (for future enhancements)
converttoformats() {
	echo -e "\n\tconverting ${manuscript%.md}..."
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript%.md}, trying to convert it" >> "$workingDir/$eventslog"

	# call specific conversions
	converttohtml
	converttopdf
	converttoxml

	# archive the processed manuscript
	cp "$manuscript" "$workingDir/archive/layout-versions/$today/${manuscript%.md}-$(date +"%Y-%m-%dT%H:%M:%S").md"
	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   copy of ${manuscript%.md} archived" >> "$workingDir/$eventslog"
}

# Do you want to run conversion on a specific article?
if [ -z ${@+x} ]; then
	echo -e "\tno file specified"

	printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Starting conversion of manuscripts in ./1-layout..." >> "$workingDir/$eventslog"
	( # start subshell
		if cd ./1-layout ; then
			echo "Starting conversions..."
		else
			echo "WARNING: ./1-layout directory not found!"
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$workingDir/$eventslog"
			exit 77
		fi

		# check if there are valid files
		EXT=(`find ./ -maxdepth 1 -regextype posix-extended -regex '.*\.(md)$'`)
		if [ ${#EXT[@]} -gt 0 ]; then
			: # valid files, ok
		else
			printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] No valid files found in ./1-layout, exiting now" >> "$workingDir/$eventslog"
			echo "WARNING: no valid files!"
			exit 77
		fi

		# convert valid files
		for markdown in ./*.md; do
			manuscript=${markdown#.\/};
			# launch conversion
			converttoformats

		done
	) # end subshell

else # we have a parameter: convert only specified file
	for parameter in $@; do
		echo -e "\nparameter is set to '$parameter'";
		manuscript=${parameter#.\/1-layout\/};

		( # start subshell
			if cd ./1-layout ; then
				echo "Starting conversions..."
			else
				echo "WARNING: ./1-layout directory not found!"
				printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$workingDir/$eventslog"
				exit 77
			fi

			converttoformats

		) # end subshell
	done

fi

echo -e "\nWe are done here!"
