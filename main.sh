#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/projects.sh


NUM_ARGS=$#

function helpDisplay() {
	echo "proj [FUNCTION]"
	echo "= Functions ="
	echo "help - Print this message"
	echo "goto - Show all projects and select where to go"
	echo "mark - Mark current folder as current project"
	echo "init - Set up a project file"
	echo "data - Show current data"
	echo "back - Go to current marked project"
	echo "void - Remove a project from tracking"
	echo "list - Show all proejcts"
}


function intro() {
	printGreen "Project Manager - V1"
	echo ""
	if [ $NUM_ARGS -eq 0 ]; then
		helpDisplay
	else
		# Collect current data
		if [ -f $PROJ_LOC ]; then
			DATA=$(cat $PROJ_LOC)
		else
			echo "No project file found, creating"
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
				;;
			"mark")
				mark
				;;
			"init")
				init
				;;
			"help")
				helpDisplay
				;;
			"data")
				showData
				;;
			"back")
				gotoMark
				;;
			"void")
				delProject
				;;
			"list")
				showProjects
				;;
            "todo")
                todo
                ;;
			*)
				echo "Command not recognized: $arg"
				;;
		esac
	done
}
### MAIN SCRIPT STARTS HERE ###
intro
process "$@"