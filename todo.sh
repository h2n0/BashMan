# All functions related to 'todo' actions
# beling here

# todo function, show current and completed tasks to user
# about the project in the current directory or about
# another project in general
function todo() {

    # Check if inside a project directory
    local INPROJ=$(jsonRead | jq ".projects[].dir == \"$(pwd)\"" | grep "true")
    local INDEX=-1
    if [ -z $INPROJ ]; then # Not in a projects so selection
        projectSelect "What project would you like to see the todo list of?"
        CHOICE=$?
        CHOICE=$(( $CHOICE - 1 ))
        INDEX=$CHOICE
    else # Inside a project
        INDEX=$(getProjectIndexFromDirectory)
    fi

    jsonRead ".projects[$INDEX].todo" | grep null > /dev/null
    if [ $? -eq 0 ]; then # Project has no todo
        echo "Project has no TODOs"
        echo "Would you add one (Y/n)"
        read -n1 < OPTION
        #jsonUpdate ".projects[$INDEX].todo = []"
    else
        echo "JIO"
    fi
}

# Create a new todo object and append the array of given project
function newTodo() {
    INDEX=$1
    TITLE=""
    DESC=""
    DATE_ADDED=$(date)
    echo "What would you like to name the task?"
    read -p "> " TITLE

    TMP_TASK=/tmp/projtask.tmp
    echo "# What is the description of the task" > $TMP_TASK
    nano $TMP_TASK
    DESC=$(cat $TMP_TASK | tail -n +2)

    DATA="{\"title\":\"$TITLE\", \"desc\":\"$DESC\", \"date-added\":\"$DATE_ADDED\", \"complete\":false}"
    jsonUpdate ".projects[$INDEX].todo += [$DATA]"
}

function listTodos() {
    INDEX=$1
}