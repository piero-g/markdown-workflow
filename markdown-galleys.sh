#!/bin/bash
#
# Convert each article from markdown ("./1-layout/" directory) to the final
# publication files (galleys), and save in "./2-publication/" directory.
# All the events are logged.
# Also archive a backup copy of the markdown version and log all the events
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
printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] markdown-galleys.sh started running, logging events" >> "$workingDir/$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR


######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p $workingDir/{archive/layout-versions,2-publication}
# creating only the directories pertaining this part of the workflow
printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$workingDir/$eventslog"

######
# 2. parse options and parameters, if getopt isn't too old
######

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

OPTIONS=pHxwbh
LONGOPTIONS=pdf,html,xml,word,backup,help

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
		# e.g. $? == 1
		#  then getopt has complained about wrong arguments to stdout
		exit 2
fi

# help
function printHelp() {
  cat <<EOF

This script performs the main conversions, from markdown files in 1-layout
to galley formats in 2-publication.
It will run on all .md files in 1-layout/, if no arguments are specified
(arguments must include the folder name)

The following options are supported:
-h, --help      display this message and exit
-p, --pdf       convert only in PDF
-H, --html      convert only in HTML
-x, --xml       convert only in JATS XML
-w, --word      convert only in DOCX
                  (useful for additional copyediting or antiplagiarism)
-b, --backup    don't convert, just backup in ./archive/layout-versions/

EOF
}

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
	case "$1" in
		-h|--help)
			printHelp
			exit 1
			;;
		-p|--pdf)
			p=y
			shift
			;;
		-H|--html)
			h=y
			shift
			;;
		-x|--xml)
			x=y
			shift
			;;
		-w|--word)
			w=y
			shift
			;;
		-b|--backup)
			b=y
			shift
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


######
# 2.1 check if sections will be numbered (default) or unnumbered
#     see `./z-lib/journal.conf` for unnumbered_sections (true or false)
#     parameter evalued by `./z-lib/events-logger.sh`
######
if [ $unnumbered_sections ] && [ $unnumbered_sections == true ]; then
	echo "sections will be unnumbered (default is numbered)"
	sectionNum=""
else
	sectionNum="-N"
fi


######
# 3. conversion, change extension, not filename; then archive manuscript
######

# prepare daily subdirectory for layout-versions archiving
mkdir -p "$workingDir/archive/layout-versions/$today"

# conversion functions
converttohtml() {
	# HTML conversion with Pandoc  --embed-resources --standalone
	pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" ${sectionNum} --toc --citeproc --email-obfuscation=references --section-divs --embed-resources --standalone --template="$workingDir/z-lib/article.html5" --write=html5 --default-image-extension=.low.jpg -o "$workingDir/2-publication/${manuscript%.md}.html"
}
converttopdf() {
	# PDF conversion with Pandoc # -N --toc
	pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" ${sectionNum} --toc --citeproc --template="$workingDir/z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.pdf"
	# LaTeX
	pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" ${sectionNum} --toc --citeproc --template="$workingDir/z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.tex"
}
converttoxml() {
	# JATS XML
	pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" ${sectionNum} --toc --citeproc --template="$workingDir/z-lib/article.jats" --write=jats --wrap=none --default-image-extension=.jpg -s -o "$workingDir/2-publication/${manuscript%.md}.jats.xml"
	# TEI XML
	#pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" --toc ${sectionNum} --citeproc --template="$workingDir/z-lib/article.tei" --write=tei -s -o "$workingDir/2-publication/${manuscript%.md}.tei.xml"
}
# this is just a test
converttoword() {
	# DOCX format # --reference-doc="$workingDir/z-lib/article.docx"
	pandoc "$workingDir/z-lib/journal.yaml" "$workingDir/z-lib/issue.yaml" "${manuscript}" ${sectionNum} --toc --citeproc  -w docx+styles  -s -o "$workingDir/2-publication/${manuscript%.md}.docx"
}
# generic function that calls the specific conversions
converttoformats() {
	echo -e "\n\tconverting ${manuscript%.md}..."
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")]   ${manuscript%.md}, trying to convert it" >> "$workingDir/$eventslog"

	# if backup don't run any conversion
	if [ $b ]; then
		if [ $p ] || [ $h ] || [ $x ] || [ $w ]; then
			echo -e "\t[WARN] backup only, no conversion will run"
		else
			echo -e "\tbackup only"
		fi
		printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")]   backup only!" >> "$workingDir/$eventslog"
	else
		# no backup, proceed with conversions
		if [ $p ] || [ $h ] || [ $x ] || [ $w ]; then
			echo -e "\tconverting only to the specified formats"
		else
			echo -e "\tno options given, preparing all formats"
			printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")]   no options given, preparing all formats" >> "$workingDir/$eventslog"
			converttohtml
			converttopdf
			converttoxml
			# no converttoword, use it only when explicitly requested
		fi

		if [ $h ]; then
			converttohtml
		fi

		if [ $p ]; then
			converttopdf
		fi

		if [ $x ]; then
			converttoxml
		fi

		if [ $w ]; then
			converttoword
		fi
	fi # end check on backup

	# archive the processed manuscript
	cp "$manuscript" "$workingDir/archive/layout-versions/$today/${manuscript%.md}-$(date +"%Y-%m-%dT%H-%M-%S").md"
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")]   copy of ${manuscript%.md} archived" >> "$workingDir/$eventslog"
}

# log the specified command options
printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] command options: $PARSED" >> "$workingDir/$eventslog"

# Do you want to run conversion on a specific article?
if [ -z ${@+x} ]; then
	echo -e "\tno file specified"

	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] Starting conversion of manuscripts in ./1-layout..." >> "$workingDir/$eventslog"
	( # start subshell
		if cd ./1-layout ; then
			echo "Starting conversions..."
		else
			echo "WARNING: ./1-layout directory not found!"
			printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$workingDir/$eventslog"
			exit 77
		fi

		# check if there are valid files
		EXT=(`find ./ -maxdepth 1 -regextype posix-extended -regex '.*\.(md)$'`)
		if [ ${#EXT[@]} -gt 0 ]; then
			: # valid files, ok
		else
			printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")]   [WARN] No valid files found in ./1-layout, exiting now" >> "$workingDir/$eventslog"
			echo "WARNING: no valid files!"
			exit 77
		fi

		# convert valid files
		for markdown in ./*.md; do
			manuscript="${markdown#.\/}"
			# launch conversion
			converttoformats

		done
	) # end subshell

else # we have a parameter: convert only specified file
	for parameter in "$@"; do
		echo -e "\nparameter is set to '$parameter'";
		manuscript="$( echo "$parameter" | sed -r 's/^\.?\/?1\-layout\///' )"

		( # start subshell
			if cd ./1-layout ; then
				echo "Starting conversions..."
			else
				echo "WARNING: ./1-layout directory not found!"
				printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: ./1-layout directory not found! Aborting." >> "$workingDir/$eventslog"
				exit 77
			fi

			converttoformats

		) # end subshell
	done

fi

echo -e "\nWe are done here!"
