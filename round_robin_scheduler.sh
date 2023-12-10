#!/bin/bash

# Author: Ben Hogg

# Version: 1.0

# Description:
# This script implements the round-robin scheduling algorithm, simulating how processes are fairly allocated to a CPU without conflicts. It takes as input a data file containing process names, NUT values, and arrival times.
# The design involves mapping each process's details to a single index, facilitating efficient tracking and modification. Processes initially enter the new queue based on their arrival times, matched with a time variable that increments with each time slice.
# Processes transition from the new queue to the accepted queue when their priority is equal to or greater than those in the accepted queue. The algorithm iterates until all processes have completed their CPU servicing time.
# Users can customize quanta and priority values through the parameters. 
# Output options include displaying results on screen or saving them to a file.

# Terminology: 
# - "NUT" refers to the Normalized Utilization Time. This is the maximum amount of turns a process can use the CPU consecutively.
# - "Time slice" refers to the unit of time in the scheduling algorithm.
# - "Priority" determines the order in which processes move from the new queue to the accepted queue.

# File Format:
# The data file should be a plain text file with columns specifying process names, NUT values, and arrival times.

# Parameters:
# $1 Regular data file
# $2 New queue priority increment setting
# $3 Accepted queue priority increment setting

# Example:
# ./round_robin_scheduler.sh input_data.txt 2 5


# Program starts here...

# Validates and assigns inputs
if [ "$#" -eq 3 ]; then
    dataFile="$1"
    newIncrement="$2"
    acceptedIncrement="$3"
    quanta=1
elif [ "$#" -eq 4 ]; then
    dataFile="$1"
    newIncrement="$2"
    acceptedIncrement="$3"
    quanta="$4" # (Charalambous, 2023)
else
    echo "The number of parameters is invalid. Please enter a file name with 2 or 3 parameters"
    exit 1
fi

if [ ! -f "$dataFile" ]; then
    echo "The data file you entered is not a regular file. Please try again with the name of a regular file"
    exit 1
fi

if [[ ! "$newIncrement" =~ ^[0-9]+$ || ! "$acceptedIncrement" =~ ^[0-9]+$ || ! "$quanta" =~ ^[0-9]+$ ]]; then # Stack Overflow (n.d.)
    echo "The parameters you entered are not valid"
    exit 1 
fi 

# Assign data to appropriate arrays
name=()
service=()
arrival=()
priority=()
status=()
referenceIndex=()
newQueue=()
acceptedQueue=()
quantaArray=()

while read -r name_var service_var arrival_var # (Charalambous, 2023)
do
    quantaArray+=("$quanta")
    priority+=("0")
    status+=("-")
    name+=("$name_var")
    service+=("$service_var")
    arrival+=("$arrival_var")
done < "$dataFile"

for ((i=0; i<${#name[@]}; i++)); do
    referenceIndex+=("$i")
done

# Displays input settings
echo
echo "You have chosen the following settings..."
echo
echo "Data file: $dataFile"
echo "New queue increment set to: $newIncrement"
echo "Accepted queue increment set to: $acceptedIncrement"
echo "quanta set to: $quanta"
echo

# Displays data file
echo "Contents of the data file:"
cat "$dataFile"
echo

# Reads and validates output settings
while true; do
    echo "How would you like the output of the program displayed?"
    echo "1. Display the output on screen"
    echo "2. Store the output in a file"
    echo "3. Display the output on screen and store it in a file"

    read -p "Enter your choice (1, 2, or 3): " choice

    if [ "$choice" == "1" ]; then
        echo
        echo "Output will be displayed on screen."
        echo
        break

    elif [ "$choice" == "2" ]; then
        echo
        read -p "Enter the file name to store the output: " fileName
        echo
        break

    elif [ "$choice" == "3" ]; then
        echo
        read -p "Enter the file name to store the output: " fileName
        echo "Output will be displayed on screen and stored in the file: $fileName."
        echo
        break

    else
        echo "Invalid choice. Please enter 1, 2, or 3."
        echo
    fi
done

time=0

# Main loop
while [[ $(IFS=; echo "${status[*]}") =~ [^F]+ ]]; do # (Stack Overflow, n.d.)

    # Removes finished elements and updates status to F
    for ((i = ${#acceptedQueue[@]} - 1; i >= 0; i--)); do
        element=${acceptedQueue[i]}
        if [ "${service[$element]}" -eq 0 ]; then
            status[$element]="F"
            acceptedQueue=("${acceptedQueue[@]:0:i}" "${acceptedQueue[@]:i+1}") # (Stack Exchange, n.d.)
        fi
    done

    # Moves the first process to arrive directly into the accepted queue and all other arriving processes into the new queue
    for ((i=0; i<${#referenceIndex[@]}; i++)); do
        if [ "$time" -eq "${arrival[$i]}" ]; then
            if [[ ${#acceptedQueue[@]} == 0 ]] && [[ ${#newQueue[@]} == 0 ]]; then
                acceptedQueue+=("${referenceIndex[i]}")
                status[i]="R"
            else 
                newQueue+=("${referenceIndex[i]}")
                status[i]="W"
            fi
        fi
    done

    # Increments priorities
    for ((i=0; i<${#newQueue[@]}; i++)); do
        relevantIndex=${newQueue[i]}
        if [[ -n $relevantIndex && $relevantIndex =~ ^[0-9]+$ ]]; then # =~ ^[0-9]+$ to filter out invalid elements # Stack Overflow (n.d.)
            ((priority[$relevantIndex] += $newIncrement))
        fi
    done
   
    for ((i=0; i<${#acceptedQueue[@]}; i++)); do
        relevantIndex=${acceptedQueue[i]}
        if [[ -n $relevantIndex && $relevantIndex =~ ^[0-9]+$ ]]; then
            ((priority[$relevantIndex] += $acceptedIncrement))
        fi
    done

    # Introduces processes from the new queue into the accepted queue
    if [[ ${#acceptedQueue[@]} != 0 ]] && [[ ${#newQueue[@]} != 0 ]]; then
        for ((i=0; i<${#newQueue[@]}; i++)); do
            for ((j=0; j<${#acceptedQueue[@]}; j++)); do
                if [[ ${priority[${newQueue[i]}]} -ge ${priority[${acceptedQueue[j]}]} ]]; then
                    element=("${newQueue[i]}")
                    if [[ "$element" =~ ^[0-9]+$ ]]; then 
                        acceptedQueue=("${acceptedQueue[@]}" "$element")
                        newQueue=("${newQueue[@]:0:i}" "${newQueue[@]:i+1}")          
                    fi
                fi
            done
        done
    fi

    # Introduces processes from the new queue into the accepted queue: For cases when the accepted queue is empty
    if [[ ${#acceptedQueue[@]} = 0 ]] && [[ ${#newQueue[@]} != 0 ]]; then
        acceptedQueue=("${newQueue[0]}")
        newQueue=("${newQueue[@]:1}")
    fi

    # Adjusts values for process in service position
    if [ "${#acceptedQueue[@]}" -gt 0 ]; then
        relevantIndex="${acceptedQueue[0]}"
        ((service[$relevantIndex]--))
        ((quantaArray[$relevantIndex]--))
        status[$relevantIndex]="R"
    fi

    # Displays and stores output
    if [ "$choice" -eq 1 ] || [ "$choice" -eq 3 ]; then
        if [ "$time" -eq 0 ]; then
            echo "T   ${name[*]}" | tr ' ' '   '
        fi
    fi

    if [ "$choice" -eq 2 ] || [ "$choice" -eq 3 ]; then
        if [ "$time" -eq 0 ]; then
            echo "T   ${name[*]}" | tr ' ' '   ' >> "$fileName" # (Ask Ubuntu, n.d.)
        fi
    fi

    if [ "$choice" -eq 1 ] || [ "$choice" -eq 3 ]; then
        echo "$time   ${status[*]}"
    fi

    if [ "$choice" -eq 2 ] || [ "$choice" -eq 3 ]; then
        echo "$time   ${status[*]}" >> "$fileName"
    fi

    # Sends leading process to the back of the accepted queue
    if [ "${#acceptedQueue[@]}" -gt 0 ] && [ "${quantaArray[${acceptedQueue[0]}]}" -eq 0 ]; then
            element="${acceptedQueue[0]}"
            quantaArray[$element]=$quanta
            acceptedQueue=("${acceptedQueue[@]:1}")
            acceptedQueue+=("$element")
            status[$element]="W" 
    fi

    ((time++))

done

# Exit display
echo
echo "All processes have finished."
echo
    if [ "$choice" -eq 2 ] || [ "$choice" -eq 3 ]; then
        echo "The results have been saved to: $fileName"
        echo
    fi

exit 0