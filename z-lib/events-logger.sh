#####
# events log
#####
today=$(date +"%Y-%m-%d")
eventslog="$today-events.log"

if [ ! -e "$eventslog" ]; then
	for oldlog in *-events.log; do
		## Check if the glob gets expanded to existing files.
		## If not, oldlog here will be exactly the pattern above
		## and the exists test will evaluate to false.
		[ -e "$oldlog" ] && echo "Old logs do exist, archiving" && mv *-events.log ./archive/ || :
		## This is all we needed to know, so we can break after the first iteration
		break
	done
	touch "$eventslog" && echo "Creating today's events log"
else
	echo "Today's events log does exist"
	printf "\n\n######\n\n" >> "$eventslog" # add separator
fi
