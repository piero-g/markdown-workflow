#!/bin/bash
#
# Convert each image in corresponding ./layout/media_NNNN/ folder scaling it
# to the given maximum width and height.
# Two versions are created: a 300dpi version for PDF, a low resolution version
# for HTML
#
# Future desiderata are: compression via TinyPNG API, renaming,
# orientation fix etc
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

OPTIONS=ilpDd:Lw:h
LONGOPTIONS=identify,log,preserve,density,dpi:,lowres,widthlow:,help

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

# keep track of every script run
today=$(date +"%Y-%m-%d")
eventslog="../../$today-events.log"
if [ ! -e "$eventslog" ]; then
	echo "I am currently in $PWD and I couldn't find ${eventslog}:"
	echo "is it the right place?"
	echo "This command won't be logged in the daily events log"
else
	echo "Today's events log does exist"
	printf '%b\n' "\n######\n" >> "$eventslog" # add separator
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] img-compress.sh started running in $PWD" >> "$eventslog"
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] current command options: $PARSED" >> "$eventslog"
	printf '%b\n' "\n######\n" >> "$eventslog" # add separator
fi

if [[ $? -ne 0 ]]; then
		# e.g. $? == 1
		#  then getopt has complained about wrong arguments to stdout
		exit 2
fi

# help
function printHelp() {
  cat <<EOF

This script must run inside each media folder, it will prepare the files.
The first conversion run should always be on all the images.
later you may perform actions on one or more images.
Accepted formats are jpg, png, tif.

The following options are supported:
-h, --help          display this message and exit
-i, --identify      print type, size, resolution (density) and colorspace
-l, --log           save --identify or --density to imagelog
-p, --preserve      don't convert PNG to JPG
-D, --density       set only the given density to images, don't convert
                      (use it with --dpi)
-d, --dpi           set a different density parameter for images
                      (default: 300)
-L, --lowres        don't convert image, just recreate the low-res version
-w, --widthlow      set a custom width for low-res version, useful with
                      --lowres and to alter width and height
                      (default: 800 with max height: 500px)

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
		-i|--identify)
			identify=y
			shift
			;;
		-l|--log)
			log=y
			shift
			;;
		-p|--preserve)
			p=y
			shift
			;;
		-D|--density)
			densityOnly=y
			shift
			;;
		-d|--dpi)
			if [ "$2" -eq "$2" ] 2>/dev/null
			then
				# set a different density
				DENSITY="$2"
			else
				echo "ERROR: --dpi must be an integer."
				printHelp
				exit 1
			fi
			shift 2
			;;
		-L|--lowres)
			lowresOnly=y
			shift
			;;
		-w|--widthlow)
			if [ "$2" -eq "$2" ] 2>/dev/null
			then
				# set a different resolution for low-res images
				lowwidth="$2"
				# set a very high parameter, since it will be managed by the width
				lowheight=1200
			else
				echo "ERROR: --widthlow must be an integer."
				printHelp
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

# a local log can be useful too
imagelog="images-events.log"
if [ ! -e "$imagelog" ]; then
	touch "$imagelog" && echo "Creating images events log"
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] img-compress.sh is running with this options: $PARSED" >> "$imagelog"
else
	echo "Images events log does exist"
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] img-compress.sh is running with this options: $PARSED" >> "$imagelog"
fi

####
# functions
####

# print type, size, resolution (density) and colorspace of an image
identifyimage() {
	identify -format '%f:\n  type    %m\n  size    %[width]x%[height]\n  density %[x]x%[y] %[units]\n  colorSp %[colorspace]\n\n' "${image}"
	if [ $log ]; then
		identify -format '%f:\n  type    %m\n  size    %[width]x%[height]\n  density %[x]x%[y] %[units]\n  colorSp %[colorspace]\n\n' "${image}" >> "$imagelog"
	else
		:
	fi
}

# density only
changedensity() {
	echo "${image}: setting density to $DENSITY"
	convert -units PixelsPerInch ${image} -density $DENSITY ${image}
	if [ $log ]; then
		printf '%b\n' "Density of ${image} is now set to $DENSITY" >> "$imagelog"
	else
		:
	fi
}

# backup image
backupimage() {
	if [ ! -e "./orig/${image}" ]; then
		echo "backup ${image} in ./orig/"
		cp "${image}" "./orig/${image}"
		printf '%b\n' "${image} archived in ./orig/" >> "$imagelog"
	else
		echo "backup ${image} in ./orig/ with datestamp, an image was already there"
		cp "${image}" "./orig/$(date +"%Y-%m-%dT%H-%M-%S")-${image}"
		printf '%b\n' "${image} archived in ./orig/ as $(date +"%Y-%m-%d %H:%M:%S")-${image}" >> "$imagelog"
	fi
}

# convert, resize, set density, make low resolution variant for HTML
convertimage() {
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
}

####
# logic
####
# Do you want to edit a specific image?
if [ -z ${@+x} ]; then
	# no file specified, run on each file within the directory
	printf '%b\n' "[$(date +"%Y-%m-%d %H:%M:%S")] Starting editing of manuscripts in ./1-layout..." >> "$eventslog"

	if [ $identify ] || [ $densityOnly ]; then
		:
	else
		echo "Warning: the conversion will be performed on every image; it should be done only once"
		echo "Do you want to proceed?  (Y or N) "
		read confirm
		if echo "$confirm" | grep -iq "^[yY]$" ; then
			echo -e "\nConverting all images with appropriate extension!\n"
			printf '%b\n' "Performing the conversion on all images" >> "$imagelog"
		else
			echo "Exiting now!"
			exit 1
		fi
	fi

	for image in *.{jpeg,jpg,png,tiff,tif} ; do
		if [ $identify ]; then
			identifyimage
		elif [ $densityOnly ]; then
			# skip "low.jpg" images, we don't care about their resolution
			if [ "${image}" != "${image%.low.jpg}" ]; then
				:
			else
				echo "${image}: setting density to $DENSITY"
				convert -units PixelsPerInch ${image} -density $DENSITY ${image}
			fi
		else
			echo -e "\n\n"
			identifyimage
			backupimage
			convert ${image} -colorspace sRGB ${image}
			convertimage
		fi
	done

else # we have a parameter: convert only specified file
	for parameter in "$@"; do
		echo -e "\nparameter is set to '$parameter'";
		image=${parameter}
		if [[ $image =~ \.(jpeg|jpg|png|tiff|tif)$ ]]; then
			if [ $identify ]; then
				identifyimage
			elif [ $densityOnly ]; then
				# skip "low.jpg" images, we don't care about their resolution
				if [ "${image}" != "${image%.low.jpg}" ]; then
					echo "WARNING: You specified a low resolution image, so density won't be set!"
				else
					echo "${image}: setting density to $DENSITY"
					convert -units PixelsPerInch ${image} -density $DENSITY ${image}
				fi
			elif [ $lowresOnly ]; then
				# generate only low-res version
				if [ "${image}" != "${image%.${EXTJPG}}" ]; then
					convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTJPG}}.low.jpg
					echo "generated low-res version for ${image} with width: $lowwidth"
				fi
			else
				identifyimage
				backupimage
				convertimage
			fi

		else
			echo "WARNING: $image is not valid!"
			printHelp
			exit 1
		fi
	done
fi

shopt -u nullglob # Unsets nullglob
