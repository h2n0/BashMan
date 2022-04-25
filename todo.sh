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

# List all the todo projects in order of most recently added
function listTodos() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")
    NAME=$(echo $PROJ | jq .name | tr -d '"')
    echo "$NAME - TODOs"

    INDEX=0
    TODO_TITLES=$(echo $PROJ | jq '[.todo[].title] | sort_by(".date-added") | reverse | @csv')
    NUM_TODOS=$(echo $PROJ | jq '.todo | length')
    OLD_IFS=$IFS
    IFS=,
    read -ra TITLES <<< $TODO_TITLES
    IFS=$OLD_IFS

    if [ $NUM_TODOS -le 1 ]; then
        return 0
    fi

    for TITLE in ${TITLES[@]}; do
        TITLE=$(echo $TITLE | tr -d '"\\')
        CURRENT_TODO=$(echo $PROJ | jq ".todo | sort_by(\".date-added\") | reverse | .[$INDEX]")
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


# Remove a task from the todo list
function delTodo() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")
    TODO_TITLES=$(echo $PROJ | jq '.todo | map(.title) | @csv')
    NUM_TODOS=$(echo $PROJ | jq '.todo | length')
    if [ $NUM_TODOS -lt 1 ]; then
        echo "Look like there are no tasks to delete"
        return 0
    fi

    echo ""
    echo "Which TODO would you like to remove?"
    OLD_IFS=$IFS
    IFS=,
    read -ra TITLES <<< $TODO_TITLES
    IFS=$OLD_IFS
    local DINDEX=0
    for TITLE in ${TITLES[@]}; do
        TITLE=$(echo $TITLE | tr -d '\\"')
        VINDEX=$(( $DINDEX + 1 ))
        echo "$VINDEX - $TITLE"
        DINDEX=$(( $DINDEX + 1 ))
    done

    read -p "> " OPTION
    OPTION=$(( $OPTION - 1 ))

    if [ -z $OPTION ] || [ $OPTION -gt ${#TITLES[@]} ] || [ $OPTION -lt 0 ]; then
        echo "Not a valid option"
        return 0
    else
        SELECTED_TITLE=$(echo ${TITLES[$OPTION]} | tr -d '\\"')
        SELECTED_INDEX=$(echo $PROJ | jq ".todo | map(.title) | index(\"$SELECTED_TITLE\")")
        jsonUpdate ".projects[$INDEX].todo = (.projects[$INDEX].todo - [.projects[$INDEX].todo[$SELECTED_INDEX]])"
    fi
}

# Mark a task in the todo list and complete
function completeTodo() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")
    TODO_TITLES=$(echo $PROJ | jq '.todo | map(select(.complete == false)) | map(.title) | @csv')
    NUM_TODOS=$(echo $PROJ | jq '.todo | map(select(.complete == false)) | length')
    if [ $NUM_TODOS -lt 1 ]; then
        echo "Look like your all finished"
        return 0
    fi
    echo ""
    echo "Which TODO would you like to mark as complete?"

    OLD_IFS=$IFS
    IFS=,
    read -ra TITLES <<< $TODO_TITLES
    IFS=$OLD_IFS
    local DINDEX=0
    for TITLE in ${TITLES[@]}; do
        TITLE=$(echo $TITLE | tr -d '\\"')
        VINDEX=$(( $DINDEX + 1 ))
        echo "$VINDEX - $TITLE"
        DINDEX=$(( $DINDEX + 1 ))
    done

    read -p "> " OPTION
    OPTION=$(( $OPTION - 1 ))

    if [ -z $OPTION ] || [ $OPTION -gt ${#TITLES[@]} ] || [ $OPTION -lt 0 ]; then
        echo "Not a valid option"
        return 0
    else
        SELECTED_TITLE=$(echo ${TITLES[$OPTION]} | tr -d '\\"')
        SELECTED_INDEX=$(echo $PROJ | jq ".todo | map(.title) | index(\"$SELECTED_TITLE\")")
        jsonUpdate ".projects[$INDEX].todo[$SELECTED_INDEX].complete |= true"
    fi
}