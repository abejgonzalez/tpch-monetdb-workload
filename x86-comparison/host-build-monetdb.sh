#!/bin/bash

set -ex

echo "Install required packages"
sudo yum install -y bison cmake cmake3 openssl-devel pkgconf python3 git

echo "Install recommended packages"
sudo yum install -y bzip2-devel libuuid-devel pcre-devel readline-devel xz-devel zlib-devel

BASE_DIR=$PWD
BUILD_DIR=$PWD/build-area

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
pushd $BUILD_DIR

echo "Build MonetDB"
rm -rf monetdb
git clone https://github.com/MonetDB/MonetDB.git monetdb
pushd monetdb
git checkout 19539f3 # semi-arb. commit
popd
mkdir -p monetdb-build
pushd monetdb-build
# Run the build (turn off assertions)
cmake3 \
    -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/linux-gnu.cmake \
    -DCMAKE_SUMMARY=ON \
    -DASSERT=OFF \
    -DWITH_BZ2=OFF \
    -DWITH_CMOCKA=OFF \
    -DWITH_CURL=OFF \
    -DWITH_LZMA=OFF \
    -DWITH_PCRE=OFF \
    -DWITH_PROJ=OFF \
    -DWITH_READLINE=OFF \
    -DWITH_UUID=OFF \
    -DWITH_VALGRIND=OFF \
    -DWITH_XML2=OFF \
    -DWITH_ZLIB=OFF \
    -DPY3INTEGRATION=OFF \
    -DRINTEGRATION=OFF \
    ../monetdb
cmake3 \
    --build . --verbose
sudo cmake3 \
    --build . --target install

sudo pip3 install -U monetdb-stethoscope

echo "Testing installation"
which monetdb
which mserver5
which stethoscope

popd
popd
