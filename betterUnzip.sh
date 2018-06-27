#!/bin/bash
FILE="$1"
DESIRE_PATH=${FILE%/*}
FILENAME="$(basename "$FILE")"
EXTENSION="${FILENAME//*.}"  #replace all *.
FILENAME_PATTERN=${FILENAME/.*} #replace .*

# TODO: SUPPORT NESTED ZIP FILE
# CHECK IF A FILE SHOULD BE PROCESSED
function isOK {
	# USE A FAKE (WRONG) PASSWORD TO DETECT IF A ARCHIEVE IS ENCRYPTED
	info=$(7z l -p8xGcx382HViqDADbCoNP2Pw4MPb2m467 "$FILE" 2>&1) #COMBINE STDERR TO STDOUT
 	index=`echo "$info" | grep "Volume Index" | cut -d"=" -f 2`
	errors=`echo "$info" | grep "Errors"`
	# IF ARCHIVE IS SPLITTED, THE ARCHIVE INDEX SHOULD BE 0, TO AVOID REDUNDANT PROCESSING
	if [[ -z "$errors" &&  (-z "$index" || $index -eq 0)  ]]; then 
		echo true
	else
		# TODO: SHOULD NOT BE TRIGGERED FOR ALL SPLITED FILES
		if [[ ! -z "$errors" ]]; then
			error=`echo "$info" | grep "Wrong password"`
			if [[ ! -z "$error" ]]; then
				# SEND A NOTIFICATION
				osascript -e "display notification \"$FILE\" with title \"Encrypted Archive!\" subtitle \"need password!\" sound name \"Basso\""
			fi
		fi
		echo false
	fi 
}
CHECK=$(isOK)

if [[ $CHECK == true ]]; then
	# TRY TO UNACHIEVE
	zipResult=`7z x "$FILE" -o"$DESIRE_PATH" -aos 2>&1`
	error=`echo "$zipResult" | grep "ERROR"`
	# EVERYTHING IS FINE & FILENAME_PATTERN IS NOT EMPTY
	if [[ -z "$error" && ! -z "$FILENAME_PATTERN" ]]; then
		# SEND A NOTIFICATION
		osascript -e "display notification \"$FILE unarchived to $DESIRE_PATH\" with title \"File Unarchived\" subtitle \"$FILENAME unarchived to $DESIRE_PATH\" sound name \"Glass\""
		# MOVE ALL ASSOCIATED FILES TO TRASH
		osascript -e "tell application \"Finder\"" \
			-e	"set myList to {}" \
			-e	"set fileList to files of folder (POSIX file \"$DESIRE_PATH\")" \
			-e	"repeat with currentFile in fileList" \
			-e		"set fileName to name of currentFile" \
			-e		"if fileName starts with \"$FILENAME_PATTERN\" and fileName ends with \"$EXTENSION\" then" \
			-e			"copy currentFile to the end of myList" \
			-e		"end if" \
			-e	"end repeat" \
			-e	"move myList to trash" \
			-e	"end tell"
	fi
fi