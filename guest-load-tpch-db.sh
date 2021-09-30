#!/bin/bash

set -ex

# nav. to the script area
pushd /root/tpch-scripts

./tpch_build.sh --sf $1 --farm $PWD/monetdb-farm --load-only --verbose

poweroff
