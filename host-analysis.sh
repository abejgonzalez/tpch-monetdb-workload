#!/bin/bash

set -ex

# <SCRIPT> <ARGS> <PATH_TO_OUTPUT>
# $1 - <PATH_TO_OUTPUT>

WORKLOAD_DIR=$PWD
OUT_DIR=$1

$WORKLOAD_DIR/analysis/parse-ps-log-overall.py $OUT_DIR/prof-stethoscope.log
