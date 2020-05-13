#!/bin/bash                                                                                                                      
log() {
    stime=$(date +"%d/%m/%Y @ %T")
logfile=$(date +"%Y%m")
origin=$(caller)
loglocation="/root/logs/$logfile"
echo "[$stime] $origin:: $1" >> $loglocation
}

