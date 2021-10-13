#!/bin/bash

set -ex

# ARGS: program <TPCH SCALING FACTOR> <NUM THREADS>
SF=$1
THREADS=$2

THIS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
IP_ADDR_FILE=$THIS_DIR/ipaddr

AWS_TOOLS_DIR=~/chipyard/sims/firesim/deploy/awstools

cd $THIS_DIR

echo "Launch instance"
pushd $AWS_TOOLS_DIR
# verify instance is off
python awstools.py terminate --inst_type m5.large --clustertag benchtestx86 2>/dev/null | true
python awstools.py launch --inst_type m5.large --inst_amt 1 --clustertag benchtestx86 2>&1 | tee $IP_ADDR_FILE
popd

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

run "echo \"Working\""
copy ./linux-gnu.cmake $IP_ADDR:

# install monetdb from source on the server
run_script ./host-build-monetdb.sh

# setup and run experiment
run_script ./host-gen-tpch-data.sh $SF
run_script ./host-load-tpch-db.sh $SF
run_script ./host-run-experiment.sh $SF $THREADS

copy $IP_ADDR:tpch-scripts/03_run/SF1-noprof-results/ SF1-noprof-results
copy $IP_ADDR:tpch-scripts/03_run/SF1-prof-results/ SF1-prof-results

LOG_DIR=$THIS_DIR/logs/$(date +"%d-%b-%Y-%H-%M-%S")
mkdir -p $LOG_DIR
mv SF1-noprof-results $LOG_DIR/
mv SF1-prof-results $LOG_DIR/

echo "Shutting down instance"
pushd $AWS_TOOLS_DIR
python awstools.py terminate --inst_type m5.large --clustertag benchtestx86 2>&1 | tee $IP_ADDR_FILE
popd

rm -rf $IP_ADDR_FILE

echo "Successfully ran benchmark"
