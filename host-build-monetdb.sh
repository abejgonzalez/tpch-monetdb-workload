#!/bin/bash

# This script is setup to only work when natively compiling on Fedora

set -x

# hardcoded for now (use precrosscompiled libs from buildroot)
BUILDROOT_DIR=/home/centos/chipyard/software/firemarshal/boards/default/distros/br/buildroot/

# update packages
sudo yum update -y

echo "Install required packages"
sudo yum install -y bison cmake cmake3 openssl-devel pkgconf python3

echo "Install recommended packages"
sudo yum install -y bzip2-devel libuuid-devel pcre-devel readline-devel xz-devel zlib-devel

BASE_DIR=$PWD
BUILD_DIR=$PWD/build-area
CROSS_COMPILE_AREA=$BASE_DIR/overlay/usr

rm -rf $CROSS_COMPILE_AREA
mkdir -p $CROSS_COMPILE_AREA

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
pushd $BUILD_DIR

echo "Build MonetDB"
rm -rf monetdb
git clone https://github.com/MonetDB/MonetDB.git monetdb
pushd monetdb
git checkout cc3020d # match Jul2021-SP1 release
popd
mkdir -p monetdb-build
pushd monetdb-build
# Run the build (turn off assertions)
cmake3 \
    -DCMAKE_TOOLCHAIN_FILE=$BUILDROOT_DIR/output/host/usr/share/buildroot/toolchainfile.cmake \
    -DCMAKE_C_FLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -O3 -march=rv64gc -mabi=lp64d" \
    -DCMAKE_CXX_FLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -O3 -march=rv64gc -mabi=lp64d" \
    -DCMAKE_INSTALL_PREFIX=$CROSS_COMPILE_AREA \
    -DRELEASE_VERSION=ON \
    -DTESTING=OFF \
    -DCMAKE_SUMMARY=ON \
    -DASSERT=OFF \
    -DSTRICT=OFF \
    -DCMAKE_UNITTESTS=OFF \
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
cmake3 \
    --build . --target install

echo "Testing installation"
ls $CROSS_COMPILE_AREA/bin/monetdb
ls $CROSS_COMPILE_AREA/bin/mserver5

popd
popd

echo "Generate TPC-H Data"
./host-gen-tpch-data.sh $1
