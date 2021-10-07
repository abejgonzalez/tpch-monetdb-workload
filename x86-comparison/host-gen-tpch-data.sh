#!/bin/bash

set -ex

rm -rf tpch-scripts
git clone https://github.com/abejgonzalez/tpch-scripts.git
cd tpch-scripts

git checkout firesim-measurements

# remove the old data
rm -rf 02_load/SF-$1

# build the new data
#   use the sf passed from outside
#   generate only the data
./tpch_build.sh --sf $1 --generate-only
