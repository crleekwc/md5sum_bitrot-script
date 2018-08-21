#!/usr/bin/env bash

##############################################################
# Script name	: md5sum_bitrot
# Date created	: August 17th, 2018
# Date Modified	: Auguest 20th, 2018
# Description	: 1) check if a md5 library exists
#		  2) creates a new md5 library give a root path and path to save the library
#		  3) checks the hash library for hashes that don't match or missing files, 
#		     then stores the repective file pathes in temp logs
#		  4) check timestamp of each file where the hash doesn't match against the timestamp 
# 	 	     against the timestamp of the library file
# 
# Author	: Christopher Lee
# Email		: christopher.lee@tsc.com
# 
# Notes		: All paths to directories must end with a "/"
#		  All paths to files must NOT with "/"
# 		  Functions return 0 if there are no issues, and return 2 if there are errors to investigate
#
#
###

# Config
log_dir=./log/

# Checks if library files exist, if no library files exists executes code
# arguments:
# $1 path to library files
function init_library {
	ls "$1"*.md5 >> /dev/null 2>&1
	if [ $? -eq 2 ]
        then
        	create_libraries "$log_dir"
	fi

        return 0	
}

# Create library file of the root directory specified
# arguments:
# $1 path to root directory you want to create a md5 library of
# $2 path and filename where you want library to be stored
function create_library {
	find $1 -type f -exec md5sum {} + > $2
	
	return 0
}

# Check specified library for any mis-matched file hashes or missing files, function will return 2
# if there are mis-matched file hashes and log all mis-matched file paths in a temp_failed_<library_name>
# file so it can be used in check_timestamp. If no file is found function logs that a file is missing and
# return 0
# arguments:
# $1 path to library file
# $2 path where you want to save log files
function check_hashes {
	library_name="$( echo "$1" | rev | cut -d"/" -f1 | rev | cut -d"." -f1 )"
	state="$( md5sum -c $1 2>&1 )"
	failed="$( echo $state | grep -i FAILED | wc -l )"
	if [ $failed -eq 0 ]
	then 
		value=0
	else
		echo >> "$2"error.log
		date >> "$2"error.log
		open="$( echo "$state" | grep -i "FAILED open or read" | wc -l )"
		not_match="$( echo "$state" | grep -i "FAILED" | grep -v "FAILED open or read" | wc -l )"
		if [ $open -gt 0 ]
		then	
			echo >> "$2"read.log
			date >> "$2"read.log
			echo "$state" | grep -i "FAILED open or read" >> "$2"read.log
			echo "Files CANNOT be found:" >> "$2"error.log
			echo "$state" | grep -i "FAILED open or read" >> "$2"error.log
			value=0
		fi
		if [ $not_match -gt 0 ]
                then    
			echo "Hashes do NOT match:" >> "$2"error.log
			echo "$state" | grep "FAILED" | grep -v "FAILED open or read" >> "$2"error.log
                        echo "$state" | grep "FAILED" | grep -v "FAILED open or read" | cut -d: -f1 > "$2"temp_failed_"$library_name"
                        value=2
                fi
		
	fi

	return $value
}

# Checks timestamp of files listed in the temp_failed_<library_name> file against the time stamp of the 
# library file that the temp_failed file is associated with.
# arguments:
# $1 path to library file
# $2 log_dir
function check_timestamp {
	library="$1"
	library_name="$( echo "$1" | rev | cut -d"/" -f1 | rev | cut -d"." -f1 )"
	input="$2"temp_failed_"$library_name"
	ls "$input" >> /dev/null 2>&1
	
	if [ $? -eq 0 ]
	then 
		value=0
		while IFS=$'\n' read -r file
		do
			echo "checking $file"

			if [ $library -nt $file ];
			then
				echo >> "$2"error.log
				echo "Bitrot FOUND: $file" >> "$2"error.log
				value=2
			else
				echo "$file is good"

				if [ $value -eq 0 ] 
				then
					value=0
				else
					value=2	
				fi
			fi	
		done < $input
	else
		echo "Library NOT FOUND: $library" >> "$2"error.log
		value=2
	fi

	return $value
}

# Perform an overall check of the of the hashes if it finds mis-matched file hashes, it runs check_timestamp
# and returns 0 if there are no issues. If function returns 2 bit rot was found.
# arguments:
# $1 path to library file
# $2 log_dir
function check {
	check_hashes $1 $2
	if [ $? -gt 0 ]
	then
		check_timestamp $1 $2
	fi
	return $?
}

# Run check on all of the directories that are to be monitored. Just keep adding the checks to this function
# for ever directory you created a library for then add the return values with the current value. Check_all
# will check to see if the value is greater than 0 and return either a 0 if there are no issues, or a 2 if
# there are issues.
function check_all {
	value=0
	check "$log_dir"test.md5 "$log_dir"
	value=$(($value + $?))
	
	# check "$log_dir"test.md5 "$log_dir"
        # value=$(($value + $?))
	
	
	if [ $value -gt 0 ]
	then
		value=2
	fi
	
	return $value
}

# Creates all of the libraries. Just keep adding the create_library function with the root directory you want
# create the library for and the name of the library file. Function returns a 0 when there are no issues and
# a 2 if there are issues.
function create_libraries {
	value=0
	create_library ./ "$1"test.md5
	value=$(($value + $?))
	
	# create_library ./ "$1"test.md5
	# value=$(($value + $?))
	
	if [ $value -gt 0 ]
        then
                value=2
        fi

        return $value
}

# Below is an example on how to use the script, if you source the file in a another script remove all the 
# lines below this comment.
init_library "$log_dir"
check_all
if [ $? -eq 0 ]
then
	create_libraries "$log_dir"
	# Run rysnc
else
	echo "Bitrot found check error.log"
	# Send email notifying administrator
fi
