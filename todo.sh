# All functions related to 'todo' actions
# belong here

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

    # Check if the project even has a todo field
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
    else # Project has a todo
        listTodos $INDEX

        echo ""
        echo "========================"
        echo "What do you want to do?"
        echo "1) Complete"
        echo "2) Add"
        echo "3) Remove"
        read -p "> " OPTION

        if [ -z $OPTION ]; then # No option chosen, do nothing and leave
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
    local INDEX=$1
    TITLE=""
    DESC=""
    DATE_ADDED=$(date)
    echo "What would you like to name the task?"
    read -p "> " TITLE

    TMP_TASK=/tmp/projtask.tmp
    echo "# What is the description of the task" > $TMP_TASK
    echo "# Task title: $TITLE" >> $TMP_TASK
    nano $TMP_TASK
    DESC=$(cat $TMP_TASK | tail -n +3)
    if [ "$DESC" == "" ]; then
        echo "No description given"
        return 0
    fi

    DATA="{\"title\":\"${TITLE}\", \"desc\":\"$DESC\", \"date-added\":\"$DATE_ADDED\", \"complete\":false}"
    jsonUpdate ".projects[$INDEX].todo += [$DATA]"
}

# List all the todo projects in order of most recently added
function listTodos() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")
    NAME=$(echo $PROJ | jq .name | tr -d '"')

    LIST_TITLE="${NAME} - TODOs"
    echo "$LIST_TITLE"
    echo ""

    # Get the names of the todos and the number of them
    INDEX=0
    NUM_TODOS=$(echo $PROJ | jq '.todo | length')

    # No todos so leave the function
    if [ $NUM_TODOS -lt 1 ]; then

        # Print a centered 'None' to show user that there are no tasks
        # for them to be doing
        NONE_STR="-= None =-"
        PADDING=$(( ( ${#LIST_TITLE} - ${#NONE_STR} ) / 2 ))
        PADDED_NONE=""
        while [ $PADDING -gt 0 ]; do
            PADDED_NONE="${PADDED_NONE} "
            PADDING=$(( $PADDING - 1 ))
        done
        PADDED_NONE="${PADDED_NONE} -= None =-"
        echo "$PADDED_NONE"

        return 0
    fi

    # Sort the projects by most recent first
    SORTED_TODOS=$(echo $PROJ | jq ".todo | sort_by(\".date-added\") | reverse")
    for I in $(seq 1 ${NUM_TODOS}); do
        TITLE=$(echo $SORTED_TODOS | jq ".[$INDEX].title" | tr -d '"')
        CURRENT_TODO=$(echo $SORTED_TODOS | jq ".[$INDEX]")
        COMPLETED=$(echo $CURRENT_TODO | jq 'if .complete == false then 0 else 1 end' )
        if [ $COMPLETED -eq 1 ]; then
            printGreen "[X] $TITLE"
        else
            echo "[ ] $TITLE"
        fi

        # Apply formatting to description
        DESC=$(echo $CURRENT_TODO | jq '.desc | gsub("\n";"\n\t")')
        # Remove the '"' from either end of the string
        DESC=${DESC:1:-1}
        echo -e "\t$DESC"
        echo ""
        INDEX=$(( $INDEX + 1 ))
    done
}


# Remove a task from the todo list
function delTodo() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")

    # Sort the todos by most recent first
    SORTED_TODOS=$(echo $PROJ | jq ".todo | sort_by(\".date-added\") | reverse")
    NUM_TODOS=$(echo $SORTED_TODOS | jq '. | length')
    if [ $NUM_TODOS -lt 1 ]; then
        echo "Looks like there are no tasks to delete"
        return 0
    fi

    echo ""
    echo "Which TODO would you like to remove?"
    local DINDEX=0
    for TITLE in $(seq 1 $NUM_TODOS); do
        TITLE=$(echo $SORTED_TODOS | jq ".[$DINDEX].title" | tr -d '\\"')
        VINDEX=$(( $DINDEX + 1 )) # Virtual index, humans start counting from 1
        echo "$VINDEX - $TITLE"
        DINDEX=$(( $DINDEX + 1 ))
    done

    read -p "> " OPTION
    OPTION=$(( $OPTION - 1 ))

    if [ -z $OPTION ] || [ $OPTION -ge $NUM_TODOS ] || [ $OPTION -lt 0 ]; then
        echo "Not a valid option"
        return 0
    else
        # Remove selected index, first need to get index in sorted array
        # then find the correct index in the original array to remove
        SELECTED_TITLE=$(echo $SORTED_TODOS | jq ".[$OPTION].title" | tr -d '\\"')
        SELECTED_INDEX=$(echo $PROJ | jq ".todo | map(.title) | index(\"$SELECTED_TITLE\")")
        jsonUpdate ".projects[$INDEX].todo = (.projects[$INDEX].todo - [.projects[$INDEX].todo[$SELECTED_INDEX]])"
    fi
}

# Mark a task in the todo list as complete
function completeTodo() {
    local INDEX=$1
    PROJ=$(jsonRead ".projects[$INDEX]")
    SORTED_TODOS=$(echo $PROJ | jq ".todo | map(select(.complete == false)) | sort_by(\".date-added\") | reverse")
    NUM_TODOS=$(echo $SORTED_TODOS | jq '. | length')
    if [ $NUM_TODOS -lt 1 ]; then
        echo "Looks like your all finished"
        return 0
    fi

    echo ""
    echo "Which TODO would you like to mark as complete?"
    local DINDEX=0
    for I in $(seq 1 ${NUM_TODOS}); do
        TITLE=$(echo $SORTED_TODOS | jq ".[$DINDEX].title" | tr -d '"')
        VINDEX=$(( $DINDEX + 1 )) # Virtual index, humans start from 1 - not 0
        echo "$VINDEX - $TITLE"
        DINDEX=$(( $DINDEX + 1 ))
    done

    read -p "> " OPTION
    OPTION=$(( $OPTION - 1 ))

    if [ -z $OPTION ] || [ $OPTION -ge ${NUM_TODOS} ] || [ $OPTION -lt 0 ]; then
        echo "Not a valid option"
        return 0
    else
        # Marked selected index as completed, need to first get the index in
        # the sorted array and then find that index in the original array
        SELECTED_TITLE=$(echo $SORTED_TODOS | jq ".[$OPTION].title" | tr -d '\\"')
        SELECTED_INDEX=$(echo $PROJ | jq ".todo | map(.title) | index(\"$SELECTED_TITLE\")")
        jsonUpdate ".projects[$INDEX].todo[$SELECTED_INDEX].complete |= true"
    fi
}