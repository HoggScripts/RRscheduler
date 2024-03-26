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
# ./SDEproject.sh input_data.txt 2 5
