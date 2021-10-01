#!/bin/bash

set -ex

scaling_factor=$1
num_threads=$2

if [ $# -ne 2 ]; then
    echo "$0 <SF> <# Server Threads>"
    exit 1
fi

echo "Using SF=$scaling_factor and Threads=$num_threads"

pushd /root/tpch-scripts/03_run

##### RUN W/ PROFILING

# start the db w/ profiling enabled
./start_mserver.sh --farm /root/tpch-scripts/monetdb-farm --db SF-$scaling_factor --set gdk_nr_threads=$num_threads --stethoscope --verbose

# wait for everything to be setup (stethoscope...)
sleep 10

# run tpch
./horizontal_run.sh --db SF-$scaling_factor -v

# run extra sql to dump all tpch
mclient -d SF-$scaling_factor hello_world.sql

# kill the processes
kill $(cat /tmp/stethoscope.pid)
kill $(cat /tmp/mserver.pid)
kill -9 $(cat /tmp/stethoscope.pid) || true
kill -9 $(cat /tmp/mserver.pid) || true
tail --pid=$(cat /tmp/stethoscope.pid) -f /dev/null
tail --pid=$(cat /tmp/mserver.pid) -f /dev/null

# organize data
data_dir=SF${1}-prof-results
rm -rf $data_dir
mkdir $data_dir
mv timings.csv $data_dir/prof-timings.csv
mv /tmp/*stethoscope_log* $data_dir/prof-stethoscope.log

sleep 5

##### RUN W.O. PROFILING

# start the db w/ profiling enabled
./start_mserver.sh --farm /root/tpch-scripts/monetdb-farm --db SF-$scaling_factor --set gdk_nr_threads=$num_threads --verbose

# wait for everything to be setup (stethoscope...)
sleep 10

# run tpch
./horizontal_run.sh --db SF-$scaling_factor -v

# run extra sql to dump all tpch
mclient -d SF-$scaling_factor hello_world.sql

# kill the processes
kill $(cat /tmp/mserver.pid)
kill -9 $(cat /tmp/mserver.pid) || true
tail --pid=$(cat /tmp/mserver.pid) -f /dev/null

# organize data
data_dir=SF${1}-noprof-results
rm -rf $data_dir
mkdir $data_dir
mv timings.csv $data_dir/noprof-timings.csv

poweroff
