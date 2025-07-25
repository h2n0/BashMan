#!/usr/bin/env bash
DATA=0

function printColor {
	echo -e "\e[${2}m${1}\e[0m"
}

function printGreen {
	printColor "$1" "0;32"
}

function printYellow {
	printColor "$1" "0;33"
}

function printRed {
	printColor "$1" "0;31"
}

# Check how many arguments there are
# No need to run if we arent told what to do

function showProjects(){
	PROJS=$(jsonRead "[.projects[].name] | @csv")
	INDEX=0

	AMT=$(jsonRead ".projects | length")
	if [ $AMT -eq 0 ]; then
		echo "No projects yet!"
		return
	fi

	OLD_IFS=$IFS
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
	IFS=$OLD_IFS
}

function delProject(){
	projectSelect "Which project would you like to void?"
	CHOICE=$?
	if [ $CHOICE -eq 99 ]; then
		return 99
	fi
	# Make sure choice is valid
	CHOICE=$(( $CHOICE - 1 ))

	# Double check that the user wants to remove
	# the project if it has been marked as the
	# current one
	CURRENT=$(jsonRead ".current")
	if [ ! $CURRENT == "null" ] && [ $CHOICE -eq $CURRENT ]; then
		echo "Are you sure you want to void the current project?"
		read -p "(y/N) " VOID
		if [ -z $VOID ] && [[ ! "$VOID" =~ "(y|Y)" ]]; then
			return 99
		fi
	fi

	# Select all the projects that aren't the one we selected
	CURRENTNAME=$(jsonRead ".projects[.current].name")
	SELECTED=$(jsonRead ".projects[$CHOICE].name")

	# Change the current index
	if [ ! $CURRENTNAME == "null" ]; then
		NEWINDEX=$(jsonRead "[.projects[].name] | map(. == $CURRENTNAME) | index(true)")
		jsonUpdate ".current |= $NEWINDEX"
	fi

	echo $CURRENTNAME

	V=$(jsonRead "[ .projects[] | select(.name != $SELECTED )]")
	OUT=$(jsonUpdate ".projects = $V")
	echo $V
	echo "Removed $SELECTED from projects list!"

	return 98
}

function mark() {
	V=$(jsonRead "[.projects[].dir] | map(. ==\"$(pwd)\") | index(true) // -1 ")
	if [ $V -eq -1 ]; then
		echo "Not a project, can't mark as current!"
	else
		INDEX=$V
		jsonUpdate ".current |= $V"
		PROJ=$(jsonRead ".projects[$INDEX].name")
		echo "Updated marker for current project to => $PROJ"
	fi

}

function gotoMark(){
	V=$(jsonRead ".projects[.current]")
	NAME=$(echo "$V" | jq ".name")
	DIR=$(echo "$V" | jq ".dir" | tr -d '"')
	echo "Moving to project - $NAME"
	cd $DIR

	PROJ_NAME=$NAME
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
		DEFAULT=$(pwd | tr "/" "\n" | tail -1)
		read -p "($DEFAULT)> " NAME
		if [ ! $? -eq 0 ]; then
			echo "User terminated, exiting!"
		else
			if [ -z $NAME ]; then
				NAME=$DEFAULT
			fi
			jsonUpdate ".projects += [{\"name\": \"$NAME\", \"dir\": \"$(pwd)\"}]"
			if [ $? -eq 0 ]; then
				printGreen "Project created!"
			fi
		fi
	fi
}

function _moveto() {
	CHOICEDIR=$(jsonRead ".projects[$1].dir" | tr -d "\"")
	if [ "$(pwd)" == "$CHOICEDIR" ]; then
		echo "Already here!"
	fi

	DIR=$(jsonRead ".projects[$1]?.dir")
	if [ -z $DIR ]; then
		echo "ERROR, dir is null!"
		return 0
	else
		DIR=$(echo $DIR | tr -d '"')
		cd $DIR
		PROJ_NAME=$(jsonRead ".projects[$1].name")
	fi
}

function goto() {

	if [ -z $1 ]; then
		projectSelect "Where would you like to go?"
		CHOICE=$?
		if [ $CHOICE -eq 99 ]; then
			return 99
		else
			CHOICE=$(( $CHOICE - 1 ))

			_moveto $CHOICE
		fi
	else
		C=$(getNumberOfProjects)
		if [[ $1 -lt 1 ]] || [[ $1 -gt $C ]]; then
			echo "Invalid choice of project"
			return 99
		fi

		C=$(( $1 - 1 ))
		_moveto $C
	fi
}

function cleanup() {
	unset PROJ_LOC
	unset DATA
}

function projectSelect() {

	AMT=$(jsonRead ".projects | length")
	if [ $AMT -eq 0 ]; then
		echo "No projects yet!"
		return 99
	fi

	INDEX=0
	IFS=","
	read -ra NAMES <<< "$(getProjectNames)"
	if [ ! -z $1 ]; then
		echo "$1"
	fi

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


	# Edge case when pressing CRTL+D
	VALID=$(echo $CHOICE | grep -E "[0-9]+")
	if [ $? -eq 1 ]; then
		return 99
	else
		while [ $CHOICE -gt $(( ${#NAMES[@]} )) ] || [ $CHOICE -lt 1 ]; do
			echo "Choice not in range"
			read -p "> " CHOICE
		done
		return $CHOICE
	fi
}

function getProjectNames(){
	NAMES=$(jsonRead "[.projects[].name] | @csv")
	echo "$NAMES"
}

function getProjectInDirectory() {
	V=$(jsonRead "[.projects[].dir] | map(. ==\"$(pwd)\") | index(true) // -1 ")
	jsonRead ".projects[$V]$1"
}

function getNumberOfProjects(){
	COUNT=$(jsonRead "[.projects[].names] | length")
	echo $COUNT
}

function getProjectIndexFromDirectory() {
	V=$(jsonRead "[.projects[].dir] | map(. ==\"$(pwd)\") | index(true) // -1 ")
	echo $V
}

function renameProject(){
	INDEX=$(getProjectIndexFromDirectory)

	if [ $INDEX -eq -1 ]; then # Not in a project directory, so we need to pick one to change
		projectSelect "Please select the project you would like to rename"
		CHOICE=$?
		if [ $CHOICE  -eq 99 ]; then # No valid option chosen
			return 255
		fi
		INDEX=$(( $CHOICE - 1 ))
	fi
	echo "What would you like the rename the project to?"
	read -p "> " NEW_NAME
	if [ ! $? -eq 0 ] && [ -z $NEW_NAME ]; then
		echo "No name provided, exiting!"
		return 255
	else
		ONAME=$(jsonRead ".projects[$INDEX].name" | tr -d '"')
		jsonUpdate ".projects[$INDEX].name |= \"$NEW_NAME\""
		if [ $? -eq 0 ]; then
			echo "Successfuly updated project name. $ONAME => $NEW_NAME"
		fi
	fi
}
