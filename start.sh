#!/bin/bash

# make sure JRUBY_OPTS are set with good memory allocation
export JRUBY_OPTS="-J-XX:ReservedCodeCacheSize=100m -J-Xmn512m -J-Xms2048m -J-Xmx2048m -J-server"


cleanup() {
	echo -e "\n\n*** Exiting ***"
    rm -rf $pid_file
	exit $?
}

make_deploy_dir() {
    dir=$2/
    # make sure we are not making deploy directory inception
    if ! [[ "${dir:0:${#1}}" == "$1" ]]; then
        mkdir -p $1$2
    fi
}

deploy() {
    export -f make_deploy_dir
    export deploy_dir=deploy/
    # copy this directory structure to the deploy directory (minus the deploy directory and this script file)
    find * -type d -exec sh -c "make_deploy_dir $deploy_dir {}" \;
    rm -rf $deploy_dir$deploy_dir
    rm -rf $deploy_dir$(basename $0)
    # move any files in the deploy directory recursively to this directory
    (cd $deploy_dir; find * -type f -exec echo "Deploying file [{}]"  \; -exec sh -c 'mkdir -p ../$(dirname {})' \; -exec mv {} ../{} \;)
}

# move to the this scripts directory
cd ${0%/*}
# the file to contain the PID of this running process
pid_file=".pid"
# create the file holding the script PID if not exists
touch $pid_file

# get the jruby PID from the process bound to port 3030 if there is one
jruby_pid=$(lsof -i tcp:3030 -F p | cut -d p -f 2)
# get the shell PID from the pid file if there is one
shell_pid=$(head -n 1 $pid_file)
# kill the currently running jruby and shell processes gracefully
if [[ -n "${jruby_pid}" && -n "${shell_pid}" ]]; then
    echo "Terminating current process running on port 3030 (Jruby PID: $jruby_pid, shell PID: $shell_pid)"
    kill -INT $jruby_pid
    # sleep 5 seconds to let dashing shut down gracefully
    sleep 5
    kill -9 $shell_pid
fi
# write this shells PID to file
echo $$ > $pid_file

# capture SIGINT signal (ctrl+c) to cleanup and exit script
trap cleanup SIGINT

deploy
    
echo "Dashing starting..."
# this will return based on the cron time defined at 'restart-cron' in config.yml
dashing start

# loop to restart dashing when dashing is shutdown until SIGINT signal is captured
#while true; do
	# move any files from the deploy directory to this one
	
    
	#echo -e "\n\nRestarting server in 15 seconds..."
	#echo "Press CTRL-C again to stop from restarting"
    #this keeps restarting it?
	#sleep 15
#done