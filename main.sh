#!/usr/bin/env bash

# Global args
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
NUM_ARGS=$#
PROJ_LOC=~/.proj/projects.json

# Other function files
source $SCRIPT_DIR/json.sh
source $SCRIPT_DIR/projects.sh
source $SCRIPT_DIR/todo.sh


# Get the name / alias of the program
function getProgramName() {
	local SCRIPT=$0
	PROG_NAME=$(cat ~/.bashrc | grep $SCRIPT | grep $SCRIPT_DIR | grep -oEi 'alias .*=' | cut -b 7- | grep -oEi '^.*[^=]')

	# If not in '~/.bashrc' then check '~/.bash_aliases'
	if [ -z $PROG_NAME ]; then
		PROG_NAME=$(cat ~/.bash_aliases | grep $SCRIPT | grep $SCRIPT_DIR | grep -oEi 'alias .*=' | cut -b 7- | grep -oEi '^.*[^=]')
	fi

	echo $PROJ_NAME
}

function helpDisplay() {
	echo "$(getProgramName) [FUNCTION]"
	echo "= Functions ="
	echo "help - Print this message"
	echo "goto - Show all projects and select where to go"
	echo "mark - Mark current folder as current project"
	echo "init - Set up a project file"
	echo "data - Show current data"
	echo "back - Go to current marked project"
	echo "void - Remove a project from tracking"
	echo "list - Show all proejcts"
	echo "todo - Show current project todo"
}


function intro() {
	printGreen "BashMan - V1.1"
	echo ""
	if [ $NUM_ARGS -eq 0 ]; then
		helpDisplay
	else
		# Collect current data
		if [ -f $PROJ_LOC ]; then
			DATA=$(cat $PROJ_LOC)
		else
			echo "No project file found, creating"
			mkdir $(dirname $PROJ_LOC)
			echo "{ \"projects\": [], \"current\":null }" > $PROJ_LOC
		fi
	fi
}

# Check what we want to do
function process(){
	for arg in $1; do
		case "$arg" in
			"goto")
				goto
				if [ $? -eq 99 ]; then
					echo ""
					return 255
				fi
				;;
			"mark")
				mark
				return 255
				;;
			"init")
				init
				return 255
				;;
			"help")
				helpDisplay
				return 255
				;;
			"data")
				showData
				return 255
				;;
			"back")
				gotoMark
				;;
			"void")
				delProject
				O=$?
				if [ $O -eq 99 ]; then
					echo "Not removed from data files"
					return 255
				elif [ $O -eq 98 ]; then
					echo "Removed from data file"
					return 255
				fi
				;;
			"list")
				showProjects
				return 255
				;;
            "todo")
                todo
				return 255
                ;;
			*)
				echo "Command not recognized: $arg"
				return 255
				;;
		esac
	done

	return 0
}
### MAIN SCRIPT STARTS HERE ###
intro
if [ $NUM_ARGS -eq 0 ]; then
	exit 0
fi

process "$@"

if [ $? -eq 255 ]; then
	exit 1
fi


# Clean up vars here
cleanup
unset SCRIPT_DIR
unset NUM_ARGS
unset PROJ_LOC

#clear
echo "Now in "$PROJ_NAME", exit terminal to return to normal env"

#get Git branch name if avaliable
BRANCH=$(git status 2> /dev/null| head -1 | grep "branch")
if [ $? -eq 0 ]; then
	BRANCH=$(echo $BRANCH | awk '{print $3}' 2> /dev/null | awk -F'\n' '{ print $1}')
else
	BRANCH=""
fi

TAG=$(echo "$PROJ_NAME" | tr -d '"')
if [ "$BRANCH" != "" ]; then
	TAG=$(echo -e "$TAG => $(printGreen $BRANCH)")
fi
exec bash --rcfile <(cat ~/.bashrc; echo -e "PS1='[\033[38;5;214m$TAG\033[0m]:\033[34m\w\033[0m\$ '") -i
unset PROJ_NAME