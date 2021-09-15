#!/bin/bash

set -ex

# nav. to the script area
pushd overlay/root/tpch-scripts

# remove the old data
rm -rf 02_load/SF-$1

# build the new data
#   use the sf passed from outside
#   generate only the data
./tpch_build.sh --sf $1 --generate-only

# return back to marshal area
popd
