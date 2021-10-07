#!/bin/bash

set -ex

# ARGS: program <TPCH SCALING FACTOR> <NUM THREADS>
SF=$1
THREADS=$2

THIS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
IP_ADDR_FILE=$THIS_DIR/ipaddr

AWS_TOOLS_DIR=~/chipyard/sims/firesim/deploy/awstools

cd $THIS_DIR

#echo "Launch instance"
#pushd $AWS_TOOLS_DIR
#python awstools.py benchlaunch 2>&1 | tee $IP_ADDR_FILE
#popd
#
#echo "Wait for instance to boot"
#sleep 5m

IP_ADDR=$(grep -E -o "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" $IP_ADDR_FILE | head -n 1)

echo "Using $IP_ADDR as benchmark machine"

copy () {
    rsync -avzp -e 'ssh' --exclude '.git' $1 $2
}

run () {
    ssh -o "StrictHostKeyChecking no" -t $IP_ADDR $@
}

run_script () {
    SCRIPT=$1
    shift
    ssh -o "StrictHostKeyChecking no" -t $IP_ADDR 'bash -s' < $SCRIPT "$@"
}

copy ./linux-gnu.cmake $IP_ADDR:

# install monetdb from source on the server
run_script ./host-build-monetdb.sh

# setup and run experiment
run_script ./host-gen-tpch-data.sh $SF
run_script ./host-load-tpch-db.sh $SF
run_script ./host-run-experiment.sh $SF $THREADS

copy $IP_ADDR:tpch-scripts/03_run/SF1-noprof-results/ SF1-noprof-results
copy $IP_ADDR:tpch-scripts/03_run/SF1-prof-results/ SF1-prof-results

echo "Shutting down instance"
pushd $AWS_TOOLS_DIR
python awstools.py benchterminate
popd
