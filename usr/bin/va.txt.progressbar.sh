#!/bin/bash

bar_char_done="#"
bar_char_todo=" "
bar_percentage_scale=2

function show_progress {

    current="$1"
    total="$2"

    if [ -n $3 ]; then
        bar_size=$3
    else
        bar_size=40
    fi

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e "\nDONE"
    fi
}

function progressbar {

    current="$1"
    total="$2"

    if [ -n $3 ]; then
        bar_size=$3
    else
        bar_size=40
    fi

    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )

    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    echo -n "| ${done_sub_bar}${todo_sub_bar} | "

    if [ -n $4 ]; then
        printf "%${4}s" "${percent}%"
    fi

}

function bar {

    if [ -n $1 ]; then
        printf -- '-%.0s' $(seq 1 $1)
    fi

}
