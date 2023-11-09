#!/bin/bash

# Sample paths
paths=("KANNEL_CONF,SCRIPTS,SCRIPTS/FBII,SCRIPTS/FBII/MONITORING,SCRIPTS/FBII/MONITORING/_CONF,SCRIPTS/FBII/MONITORING/_CORE,SCRIPTS/FBII/MONITORING/_PRIVATE,SCRIPTS/FBII/TEST,SCRIPTS/FBII/TEST/SE,SCRIPTS/GIT,SCRIPTS/InterChecker,SCRIPTS/InterChecker/opt-asterisk-")

# Function to split paths into words
splitPathIntoWords() {
    echo "$1" | awk -F '[,/]' '{ for (i=1; i<=NF; i++) print $i }'
}

# Function to get unique words
getUniqueWords() {
    local uniqueWords=()
    while IFS= read -r word; do
        # Check if the word is not empty and add to uniqueWords array
        if [[ -n "$word" ]]; then
            uniqueWords+=("$word")
        fi
    done < <(splitPathIntoWords "$1" | sort -u)
    
    echo "${uniqueWords[@]}"
}

# Call the function with a sample path
uniqueWords=$(getUniqueWords "${paths[0]}")

# Print the unique words
echo "Unique Words:"
echo "$uniqueWords"
