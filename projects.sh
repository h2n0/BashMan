#!/usr/bin/env bash
PROJ_LOC=~/.proj/projects.json
DATA=0

function printColor {
	echo -e "\e[${2}m${1}\e[0m"
}

function printGreen {
	printColor "$1" "0;32"
}

# Check how many arguments there are
# No need to run if we arent told what to do

function showProjects(){
	PROJS=$(jsonRead "[.projects[].name] | @csv")
	INDEX=0


	IFS=","
	read -ra NAMES <<< "$PROJS"

	RNAMES=()
	CURRENTPROJ=$(jsonRead ".current")
	for name in ${NAMES[@]}; do
		name=$(echo $name | tr -d '\\"')
		VINDEX=$(( $INDEX + 1 ))
		if [ ! $CURRENTPROJ == "null" ] && [ $INDEX -eq $CURRENTPROJ ]; then
			printGreen "${VINDEX}) - $name (Current Project)"
		else
			echo "${VINDEX}) - $name"
		fi
		RNAMES+=($name)
		INDEX=$(( $INDEX + 1 ))
	done
}

function delProject(){
	PROJS=$(jsonRead "[.projects[].name] | @csv")
	INDEX=0


	IFS=","
	read -ra NAMES <<< "$PROJS"
	echo "Which project would you like to remove?"

	RNAMES=()
	CURRENTPROJ=$(jsonRead ".current")
	for name in ${NAMES[@]}; do
		name=$(echo $name | tr -d '\\"')
		VINDEX=$(( $INDEX + 1 ))
		if [ ! $CURRENTPROJ == "null" ] && [ $INDEX -eq $CURRENTPROJ ]; then
			printGreen "${VINDEX}) - $name (Current Project)"
		else
			echo "${VINDEX}) - $name"
		fi
		RNAMES+=($name)
		INDEX=$(( $INDEX + 1 ))
	done

	read -p "> " CHOICE
	if [ -z $CHOICE ]; then
		exit 0
	fi

	# Make sure choice is valid
	CHOICE=$(( $CHOICE - 1 ))
	if [ $CHOICE -gt $(( ${#NAMES[@]} )) ] || [ $CHOICE -lt 0 ]; then
		echo "Choice not in range"
		exit 0
	fi

	# Double check that the user wants to remove
	# the project if it has been marked as the
	# current one
	CURRENT=$(jsonRead ".current")
	if [ ! $CURRENT == "null" ] && [ $CHOICE -eq $CURRENT ]; then
		echo "Are you sure you want to void the current project?"
		read -p "(y/N) " VOID
		if [ -z $VOID ] && [[ ! "$VOID" =~ "(y|Y)" ]]; then
			exit 0
		fi
	fi

	# Select all the projects that aren't the one we selected
	PROJ=$(echo ${RNAMES[$CHOICE]})
	CURRENTNAME=$(jsonRead ".projects[.current].name")

	V=$(jsonRead "[.projects[] | select(.name != \"$PROJ\")]")
	jsonUpdate ".projects |= $V"
	echo "Removed $PROJ from projects list!"

	# Change the current index
	if [ ! $CURRENTNAME == "null" ]; then
		NEWINDEX=$(jsonRead "[.projects[].name] | map(. == $CURRENTNAME) | index(true)")
		jsonUpdate ".current |= $NEWINDEX"
	fi
}

function mark() {
	V=$(jsonRead "[.projects[].dir] | map(. ==\"$(pwd)\") | index(true) // -1 ")
	if [ $V -eq -1 ]; then
		echo "Not a project, can't mark as current!"
	else
		INDEX=$V
		jsonUpdate ".current |= $V"
		PROJ=$(jsonRead ".projects[$INDEX].name")
		echo "Updated marker for curren project to => $PROJ"
	fi

}

function gotoMark(){
	V=$(jsonRead ".projects[.current]")
	NAME=$(echo "$V" | jq ".name")
	DIR=$(echo "$V" | jq ".dir" | tr -d '"')
	echo "Moving to project - $NAME"
	cd $DIR
}

function showData() {
	echo "Showing data in editor"
	cat $PROJ_LOC > /tmp/proj.tmp
	nano /tmp/proj.tmp
	rm /tmp/proj.tmp
}

function changeValue(){
	local QUERY=$1
	local VAL=$2
	mv $PROJ_LOC temp.json
	jq -r "$QUERY"
}

function init() {

	EXISTS=$(cat $PROJ_LOC | jsonRead ".projects[].dir == \"$(pwd)\"" | grep "true")
	if [ ! -z $EXISTS ]; then
		echo "This directory is already a project!"
	else
		echo "What do you want to call this project?"
		read -p "> " NAME
		if [ ! $? -eq 0 ] && [ -z $NAME ]; then
			echo "No name prodived, exiting!"
		else
			jsonUpdate ".projects += [{\"name\": \"$NAME\", \"dir\": \"$(pwd)\"}]"
			if [ $? -eq 0 ]; then
				printGreen "Project created!"
			fi
		fi
	fi
}

function goto() {
	PROJS=$(jsonRead "[.projects[].name] | @csv")
	INDEX=0


	IFS=","
	read -ra NAMES <<< "$PROJS"
	echo "Where would you like to go?"

	CURRENTPROJ=$(jsonRead ".current")
	for name in ${NAMES[@]}; do
		name=$(echo $name | tr -d '\\"')
		VINDEX=$(( $INDEX + 1 ))
		if [ ! $CURRENTPROJ == "null" ] && [ $INDEX -eq $CURRENTPROJ ]; then
			printGreen "${VINDEX}) - $name (Current Project)"
		else
			echo "${VINDEX}) - $name"
		fi
		INDEX=$(( $INDEX + 1 ))
	done
	read -p "> " CHOICE
	if [ -z $CHOICE ]; then
		exit 0
	fi

	CHOICE=$(( $CHOICE - 1 ))
	CHOICEDIR=$(jsonRead ".projects[$CHOICE].dir" | tr -d "\"")
	if [ "$(pwd)" == "$CHOICEDIR" ]; then
		echo "Already here!"
		exit 0
	fi
	if [ $CHOICE -gt $(( ${#NAMES[@]} - 1 )) ] || [ $CHOICE -lt 0 ]; then
		echo "Choice not in range"
		exit 0
	fi

	DIR=$(jsonRead ".projects[$CHOICE]?.dir")
	if [ -z $DIR ]; then
		echo "ERROR, dir is null!"
		exit 0
	else
		DIR=$(echo $DIR | tr -d '"')
		cd $DIR
	fi
}

function jsonUpdate() {
	V=$(cat $PROJ_LOC | jq "$1")
	if [ $? -eq 0 ]; then
		echo "$V" > $PROJ_LOC
	else
		echo "ERROR with JSON update!"
	fi
}

function jsonRead() {
	cat $PROJ_LOC | jq "$1"
}
