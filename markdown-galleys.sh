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
else
	echo "Something went wrong with event logger, aborting! (is ./z-lib/ in its place?)"
	exit 1
fi
printf "[$(date +"%Y-%m-%d %H:%M:%S")] markdown-galleys.sh started running, logging events" >> "$eventslog"

# trap for exiting while in subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

######
# 1. create directory structure for working and archiving, if not already there
######

mkdir -p ./{archive/layout-versions,2-publication}
# creating only the directories pertaining this part of the workflow
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Preparing the directory structure, if not ready" >> "$eventslog"
# now a temporary folder for the whole process
#tempdir=`mktemp -d ./tmp.XXXXXXXXXXXX`
#cd ./$tempdir

######
# 2. conversion, change extension, not filename; then archive manuscript
######
printf "\n[$(date +"%Y-%m-%d %H:%M:%S")] Starting conversion of manuscripts in ./1-layout..." >> "$eventslog"
( # start subshell
	if cd ./1-layout ; then
		echo "Starting conversions..."
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
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\t[WARN] No valid files found in ./1-layout, exiting now" >> "../$eventslog"
		echo "WARNING: no valid files!"
		exit 77
	fi

	# prepare daily subdirectory for layout-versions archiving
	mkdir -p ../archive/layout-versions/$today

	# convert valid files
	for manuscript in ./*.md; do
		echo -e "\n\tconverting ${manuscript%.md}..."
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\t${manuscript%.md}, trying to convert it in PDF, HTML, TeX and JATS" >> "../$eventslog"
		# PDF conversion with Pandoc # -N --toc
		pandoc "${manuscript}" "../z-lib/issue.yaml" "../z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="../z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "../2-publication/${manuscript%.md}.pdf"
		# LaTeX
		pandoc "${manuscript}" "../z-lib/issue.yaml" "../z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="../z-lib/article.latex" --pdf-engine=xelatex --default-image-extension=.jpg -s -o "../2-publication/${manuscript%.md}.tex"
		# HTML conversion with Pandoc  --self-contained
		pandoc "${manuscript}" "../z-lib/issue.yaml" "../z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --email-obfuscation=references --section-divs --self-contained --template="../z-lib/article.html5" --write=html5 --default-image-extension=.low.jpg -o "../2-publication/${manuscript%.md}.html"
		# JATS XML
		pandoc "${manuscript}" "../z-lib/issue.yaml" "../z-lib/journal.yaml" -N --toc --filter=pandoc-citeproc --template="../z-lib/article.jats" --write=jats --default-image-extension=.jpg -s -o "../2-publication/${manuscript%.md}.jats.xml"
		# TEI XML
		#pandoc "${manuscript}" "../z-lib/issue.yaml" "../z-lib/journal.yaml" --toc -N --filter=pandoc-citeproc --template="../z-lib/article.tei" --write=tei -s -o "../2-publication/${manuscript%.md}.tei.xml"
		# archive the processed manuscript
		cp "$manuscript" "../archive/layout-versions/$today/${manuscript%.md}-$(date +"%Y-%m-%dT%H:%M:%S").md"
		printf "\n[$(date +"%Y-%m-%d %H:%M:%S")]\tcopy of ${manuscript%.md} archived" >> "../$eventslog"
	done
) # end subshell

echo "We are done here!"
