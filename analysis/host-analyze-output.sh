#!/bin/bash

set -ex

# <SF> <PATH_TO_OUTPUT>

scaling_factor=$1
out_dir=$2

# split the single log into multiple
./split-combined-log.py $out_dir/all.log

# take that and parse it
./parse-ps-log-overall.py $out_dir/
