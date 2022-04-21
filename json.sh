
#;
# jsonUpdate
# Update the project json file with $1
# @param $1 how to update the json
#"
function jsonUpdate() {
    cp $PROJ_LOC ${PROJ_LOC}.bck
	V=$(cat $PROJ_LOC | jq "$1")
	if [ $? -eq 0 ]; then
		echo "$V" > $PROJ_LOC
	else
		echo "ERROR with JSON update!"
	fi
}


#;
# jsonRead
# Returns the current project json queried with $1
# @param $1 query for the prject json file
#"
function jsonRead() {
	cat $PROJ_LOC | jq "$1"
}