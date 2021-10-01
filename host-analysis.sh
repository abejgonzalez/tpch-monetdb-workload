#!/bin/bash

set -ex

# <SCRIPT> <ARGS> <PATH_TO_OUTPUT>
# $1 - <PATH_TO_OUTPUT>

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WORKLOAD_NAME=$1
OUT_DIR=$2

$SCRIPT_DIR/analysis/parse-ps-log-overall.py $OUT_DIR/${WORKLOAD_NAME}*/prof-stethoscope.log
