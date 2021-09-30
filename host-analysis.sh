#!/bin/bash

set -ex

# <SCRIPT> <ARGS> <PATH_TO_OUTPUT>
# $1 - <PATH_TO_OUTPUT>

WORKLOAD_DIR=$PWD
WORKLOAD_NAME=$1
OUT_DIR=$2

$WORKLOAD_DIR/analysis/parse-ps-log-overall.py $OUT_DIR/$WORKLOAD_NAME/prof-stethoscope.log
