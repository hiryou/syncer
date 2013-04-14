#! /bin/sh
# Run SYNC2 as daemon/service

## FILL IN YOUR CREDENTIALS
USERNAME="hiryou"
REMOTEHOST="68.215.56.87"
REMOTEDIR="/usr/local/dev_box/"
EXCLUDED=".git .svn .tmp"

## DON'T CHANGE ANYTHING BELOW THIS LINE
PROCNAME="SYNC2"
PID=0
LIST=()

FULLSCRIPT=$(readlink -f $0)
FULLPATH=$(dirname $FULLSCRIPT)
PROCSCRIPT=$(basename $FULLSCRIPT)

# stop if user hits control-c
control_c() {
    echo -en "\n*** Sync stopped ***\n"
    exit $?
}

start() {
    _getpid
    if [ $PID -eq 0 ]; then
        _sync2exec
        echo "  $PROCNAME is now watching this directory"
    else
        echo "  $PROCNAME already watched this directory. Calm down! ;))"
    fi
}

stop() {
    _getpid
    if [ $PID -eq 0 ]; then
        echo "  $PROCNAME does not watch this directory. Stop what? ;))"
    else
        kill $PID
        PID=0
        echo "  $PROCNAME stopped watching this directory"
    fi
}

restart() {
    _getpid
    if [ $PID -ne 0 ]; then
        stop
    fi
    start
}

status() {
    _getpid
    if [ $PID -eq 0 ]; then
        echo "  $PROCNAME is NOT watching this directory"
    else
        echo "  $PROCNAME is WATCHING this directory"
    fi
}

list() {
    _getlist
    for item in ${LIST[@]}; do 
        curDir=''
        IFS=$' ' read -ra cols <<< $item
        if [ ${cols[2]} == $(pwd -P) ]; then
            curDir=" <- current directory"
        fi
        echo "  $item$curDir"
    done
}

# main function to execute sync2.0
_sync2exec() {
    # trap keyboard interrupt (control-c)
    trap control_c SIGINT

    # main program
    while true
    do
        /usr/bin/ruby $FULLPATH/syncer2.0 -s -r -u $USERNAME -H $REMOTEHOST -d $REMOTEDIR -e $EXCLUDED
        #echo -en "\n*** Syncing in progress, Ctrl-C to stop ***\n"
        sleep 3
    done &
}

_getpid() {
    IFS=$'\n' 
    procs=( $(ps aux | grep "[b]ash .*/$PROCSCRIPT" | awk '{ print $2, $11, $12; }') );
    for proc in ${procs[@]}; do 
        #echo $proc
        IFS=$' ' read -ra cols <<< ${proc}
        pid=${cols[0]}
        cmd=${cols[1]}
        script=${cols[2]}
        if [ $cmd == "bash" ] && [ $pid -ne $$ ] && ps -p $pid > /dev/null && [[ $script == */$PROCSCRIPT ]]; then 
            dir=$(pwdx $pid | awk '{ print $2 }');
            if [ $(pwd -P) == $dir -a ! -z $pid ]; then
                PID=$pid
                break
            fi
        fi
    done
}

_getlist() {
    IFS=$'\n' 
    procs=( $(ps aux | grep "[b]ash .*/$PROCSCRIPT" | awk '{ print $2, $11, $12; }') );
    for proc in ${procs[@]}; do 
        #echo $proc
        IFS=$' ' read -ra cols <<< ${proc}
        pid=${cols[0]}
        cmd=${cols[1]}
        script=${cols[2]}
        if [ $cmd == "bash" ] && [ $pid -ne $$ ] && ps -p $pid > /dev/null && [[ $script == */$PROCSCRIPT ]]; then 
            dir=$(pwdx $pid | awk '{ print $2 }');
            LIST+=("PID $pid: $dir")
        fi
    done
}


# See how we were called.
case $1 in
    start)
	    start
	    ;;
    stop)
	    stop
	    ;;
	restart)
	    restart
	    ;;
	status)
	    status
	    ;;
	list)
	    list
	    ;;
    *)
	    echo $"Usage: SYNC2 {start|stop|restart|status|list}"
        ;;
esac

exit $?


