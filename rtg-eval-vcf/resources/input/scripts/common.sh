#!/usr/bin/env bash

export CORES=`grep physical  /proc/cpuinfo |grep id|wc -l`

export MEMORY_IN_KB=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`

# memory is expressed in kb, /1024 to transform in Mb
export MEMORY_IN_MB=`echo $(( MEMORY_IN_KB / 1024 ))`

export MEMORY_FOR_PARALLEL_JOBS_IN_MB=`echo $(( MEMORY_IN_MB / ${CORES}  ))`

# terminate the execution when a sever error occurs
function dieUponError {
 message=$1
 echo "ERROR: ${message}"
 exit 1
}