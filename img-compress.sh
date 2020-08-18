#!/bin/bash
#
# Convert each image in corresponding ./layout/NNNN-media/ folder scaling it to
# the given maximum width and height.
# Two versions are created: a 300dpi version for PDF, a low resolution version for HTML
# Future desiderata are: compression via TinyPNG API, renaming etc
#
# Author: Piero Grandesso
# https://github.com/piero-g/markdown-workflow
#

maxheight=2650 # at 300dpi = 225mm (A4 main body height, circa)
maxwidth=1750 # at 300dpi = 148mm (A4 main body width, circa)
lowheight=500
lowwidth=800


# check if the folder for original files is there
if [ ! -d orig ]; then
	mkdir orig && echo "Creating ./orig/ folder"
else
	echo "./orig/ folder does exist"
fi

shopt -s nullglob # Sets nullglob

EXTPNG=png
EXTJPG=jpg
EXTJPEG=jpeg
EXTTIFF=tiff
EXTTIF=tif
DENSITY=300

######
# parse options and parameters, if getopt isn't too old
######

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
		echo "I’m sorry, getopt --test failed in this environment, exiting now!"
		exit 1
else
	# getopt is updated, parse options
	:
fi

OPTIONS=pd:
LONGOPTIONS=preserve,dpi:

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

# keep track of every script run
today=$(date +"%Y-%m-%d")
eventslog="../../$today-events.log"
if [ ! -e "$eventslog" ]; then
	echo "I am currently in $PWD and I couldn't find ${eventslog}: it is the right place? This command won't be logged"
else
	echo "Today's events log does exist"
	printf "\n\n######\n\n" >> "$eventslog" # add separator
	printf "[$(date +"%Y-%m-%d %H:%M:%S")] img-compress.sh started running in $PWD\n" >> "$eventslog"
	printf "[$(date +"%Y-%m-%d %H:%M:%S")] current command options: $PARSED\n" >> "$eventslog"
	printf "\n\n######\n\n" >> "$eventslog" # add separator
fi

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
		-p|--preserve)
			p=y
			shift
			;;
		-d|--dpi)
			if [ "$2" -eq "$2" ] 2>/dev/null
			then
				# set a different density
				DENSITY="$2"
			else
				echo "ERROR: --dpi must be an integer."
				exit 1
			fi
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


for image in *.{jpeg,jpg,png,tiff,tif} ; do
	echo -e "\n${image}:"
	identify -format '%[width] %[height]\n' ${image}
	cp ${image} ./orig/${image}
	# is it going to work?
	convert ${image} -colorspace sRGB ${image}

	if [ "${image}" != "${image%.${EXTPNG}}" ]; then
		# if "preserve"
		if [ $p ]; then
			convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTPNG}}.png
			convert ${image%.${EXTPNG}}.png -resize ${maxwidth}x${maxheight}\> ${image%.${EXTPNG}}.png
			echo "${image} converted keeped as PNG and resized (if necessary)"
		else
			convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTPNG}}.low.jpg
			convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTPNG}}.jpg
			convert ${image%.${EXTPNG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTPNG}}.jpg
			rm ${image}
			echo "${image} converted in JPG and resized (if necessary)"
		fi
	elif [ "${image}" != "${image%.${EXTJPEG}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTJPEG}}.low.jpg
		convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTJPEG}}.jpg
		convert ${image%.${EXTJPEG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTJPEG}}.jpg
		rm ${image}
		echo "${image} renamed in JPG and resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTJPG}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTJPG}}.low.jpg
		convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTJPG}}.jpg
		convert ${image%.${EXTJPG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTJPG}}.jpg
		echo "${image} resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTTIFF}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTTIFF}}.low.jpg
		convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTTIFF}}.jpg
		convert ${image%.${EXTTIFF}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTTIFF}}.jpg
		rm ${image}
		echo "${image} converted in JPG and resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTTIF}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTTIF}}.low.jpg
		convert -units PixelsPerInch ${image} -density $DENSITY ${image%.${EXTTIF}}.jpg
		convert ${image%.${EXTTIF}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTTIF}}.jpg
		rm ${image}
		echo "${image} converted in JPG and resized (if necessary)"
	fi
done

shopt -u nullglob # Unsets nullglob
