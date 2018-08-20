# md5sum_bitrot-script

This script creates md5 hash libraries of the file trees you specify. Runs a check on the files contained in those files trees and prints in an error log any files it finds a mis-matched hash for. After it checks to see if the file has been modified by the user or if bit rot occurred.  

There are two assumptions being made, with this script. The first assumption is that any file that has a mis-matched hash AND has a new modification date than the library file is considered updated, which means the file is considered intentionally changed by the user. The second assumption is that any files that have a mis-matched hash AND is older than the library is considered to have bit rot.

### Usage:
Below is an example on how to use the functions in the script. 
```
# Config
log_dir=<path to desired log directory>

... Functions ...

init_library "$log_dir"
check_all
if [ $? -eq 0 ]
then
	create_libraries "$log_dir"
	# Run rysnc
else
	# Send email notifying administrator
fi
```
In this example I create a variable called log_dir to be the desired log directory at the top of the script file. Then I run the init_library function by giving $log_dir as an argument. Then I run a check on all of the libraries I am using, and finally if there are no issues the libraries are refreshed and rsync can finally run. If there are issues it will send an email to the administrator. At this point the admin would check the error.log file to find out which file has bit rot.  

There are a couple of functions that needed to be configured for the script to be useful. The first function is "check_all":
```
function check_all {
	value=0
	check "$log_dir"test.md5 "$log_dir"
	value=$(($value + $?))
	
	# check <path to library> <path to log directory>
  	# value=$(($value + $?))
	
	
	if [ $value -gt 0 ]
	then
		value=2
	fi
	
	return $value
}
```
This is where you would add which library file to check with the log directory also on the next line you would tally up the return values. In the example above the commented part shows how to add checks, followed by the tally.

The second function that needs to be modified is the "create_libraries" function:
```
function create_libraries {
	value=0
	create_library ./ "$1"test.md5
	value=$(($value + $?))
	
	# create_library <path of root directory> <path to library>
	# value=$(($value + $?))
	
	if [ $value -gt 0 ]
        then
                value=2
        fi

        return $value
}
```
Create_libraries needs to know which directories to monitor and where the path to library will be. To add more directories you want to monitor just add them like the commented code above, first you would add the create_library function followed by the value tally.
