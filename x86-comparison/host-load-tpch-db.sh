#!/bin/bash

set -ex

# nav. to the script area
cd tpch-scripts

rm -rf /tmp/stethoscope_log_*

./tpch_build.sh --sf $1 --farm $PWD/monetdb-farm --load-only --verbose

