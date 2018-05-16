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

# add safe max values for HTML publication (eg: 800 width, a good guess for height?)
# exclusion of PNG if named differently (how?)
# 2 versions per image
# print width and height of each original image (if lower than "maxwidth"?)

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

for image in *.{jpeg,jpg,png,tiff} ; do
	echo "${image}:"
	identify -format '%[width] %[height]\n' ${image}
	cp ${image} ./orig/${image}

	if [ "${image}" != "${image%.${EXTPNG}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTPNG}}.low.jpg
		convert -units PixelsPerInch ${image} -density 300 ${image%.${EXTPNG}}.jpg
		convert ${image%.${EXTPNG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTPNG}}.jpg
		rm ${image}
		echo "${image} converted in JPG and resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTJPEG}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTJPEG}}.low.jpg
		convert -units PixelsPerInch ${image} -density 300 ${image%.${EXTJPEG}}.jpg
		convert ${image%.${EXTJPEG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTJPEG}}.jpg
		rm ${image}
		echo "${image} renamed in JPG and resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTJPG}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTJPG}}.low.jpg
		convert -units PixelsPerInch ${image} -density 300 ${image%.${EXTJPG}}.jpg
		convert ${image%.${EXTJPG}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTJPG}}.jpg
		echo "${image} resized (if necessary)"
	elif [ "${image}" != "${image%.${EXTTIFF}}" ]; then
		convert ${image} -resize ${lowwidth}x${lowheight}\> ${image%.${EXTTIFF}}.low.jpg
		convert -units PixelsPerInch ${image} -density 300 ${image%.${EXTTIFF}}.jpg
		convert ${image%.${EXTTIFF}}.jpg -resize ${maxwidth}x${maxheight}\> ${image%.${EXTTIFF}}.jpg
		rm ${image}
		echo "${image} converted in JPG and resized (if necessary)"
	fi
done

shopt -u nullglob # Unsets nullglob
