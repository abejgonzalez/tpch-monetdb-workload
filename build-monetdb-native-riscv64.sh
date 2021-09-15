#!/bin/bash

# This script is setup to only work when natively compiling on Fedora

set -x

echo "Install required packages"
sudo yum install -y bison cmake cmake3 openssl-devel pkgconf python3

echo "Install recommended packages"
sudo yum install -y bzip2-devel libuuid-devel pcre-devel readline-devel xz-devel zlib-devel

echo "Build MonetDB"
cd $HOME
git clone --depth 1 https://github.com/MonetDB/MonetDB.git monetdb
mkdir monetdb-build
cd monetdb-build
# Run the build (turn off assertions)
cmake \
    -DASSERT=OFF \
    ../monetdb
cmake --build . --verbose
cmake --build . --target install

echo "Testing installation"
which monetdb
which mserver5

echo "Installation successful"
poweroff
