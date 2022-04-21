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
        read -p "> " OPTION

        if [ -z $OPTION ] || [[ $OPTION =~ [yY] ]]; then
            newTodo
        else
            return 0
        fi
        #jsonUpdate ".projects[$INDEX].todo = []"
    else
        listTodos $INDEX

        echo "========================"
        echo "What do you want to do?"
        echo "1) Complete"
        echo "2) Add"
        echo "3) Remove"
        read -p "> " OPTION

        if [ -z $OPTION ]; then
            return 0
        elif [ $OPTION -eq 1 ]; then
            completeTodo $INDEX
        elif [ $OPTION -eq 2 ]; then
            newTodo $INDEX
        elif [ $OPTION -eq 3 ]; then
            delTodo $INDEX
        fi

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
    PROJ=$(jsonRead ".projects[$INDEX]")
    NAME=$(echo $PROJ | jq .name | tr -d '"')
    echo "$NAME - TODOs"

    INDEX=0
    TODO_TITLES=$(echo $PROJ | jq '[.todo[].title] | sort_by(".date-added") | reverse | @csv')
    OLD_IFS=$IFS
    IFS=,
    read -ra TITLES <<< $TODO_TITLES
    IFS=$OLD_IFS
    for TITLE in ${TITLES[@]}; do
        TITLE=$(echo $TITLE | tr -d '"\\')
        CURRENT_TODO=$(echo $PROJ | jq .todo[$INDEX])

        COMPLETED=$(echo $CURRENT_TODO | jq 'if .complete == false then 0 else 1 end' )
        if [ $COMPLETED -eq 1 ]; then
            printGreen "[X] $TITLE"
        else
            echo "[ ] $TITLE"
        fi

        DESC=$(echo $CURRENT_TODO | jq '.desc | tostring')
        DESC=${DESC:1:-1}
        echo -e "- $DESC"
        echo ""
        INDEX=$(( $INDEX + 1 ))
    done
}

function delTodo() {
    echo "DEL!"
}

function completeTodo() {

    $PROJ=$(readJson | jq .projects)
    TODO_TITLES=$(echo $PROJ | jq '[.todo[].title] | @csv')
    OLD_IFS=$IFS
    IFS=,
    read -ra TITLES <<< $TODO_TITLES
    IFS=$OLD_IFS
    INDEX=0
    for TITLE in ${TITLES[@]}; do
        TITLE=$(echo $TITLE | tr -d '\\"')
        VINDEX=$(( $INDEX + 1 ))
        echo "$VINDEX - $TITLE"
        $INDEX=$(( $INDEX + 1 ))
    done

    echo "Which TODO would you like to mark as complete?"
    read -p "> " OPTION
}