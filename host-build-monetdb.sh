#!/bin/bash

# This script is setup to only work when natively compiling on Fedora

set -x

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

#echo "Build zlib"
#git clone --depth 1 https://github.com/madler/zlib.git
#pushd zlib
#mkdir -p build
#pushd build
#CC=riscv64-unknown-linux-gnu-gcc \
#    ../configure --prefix=$CROSS_COMPILE_AREA
#make -j
#make -j install
#popd
#popd
#
#echo "Build bzip2"
#wget https://www.sourceware.org/pub/bzip2/bzip2-latest.tar.gz
#tar -xvf bzip2-latest.tar.gz
#pushd bzip2-1.0.8
## sed to change the
#sed -i -E 's/CC=/CC?=/g' Makefile
#sed -i -E 's/AR=/AR?=/g' Makefile
#sed -i -E 's/RANLIB=/RANLIB?=/g' Makefile
#sed -i -E 's/-O2/-O2 -fPIC/g' Makefile
#AR=riscv64-unknown-linux-gnu-ar \
#    RANLIB=riscv64-unknown-linux-gnu-ranlib \
#    CC=riscv64-unknown-linux-gnu-gcc \
#    make -j PREFIX=$CROSS_COMPILE_AREA install
#popd
#
#echo "Build readline"
#wget ftp://ftp.cwru.edu/pub/bash/readline-8.1.tar.gz
#tar xvf readline-8.1.tar.gz
#pushd readline-8.1
#mkdir -p build
#pushd build
#CC=riscv64-unknown-linux-gnu-gcc \
#    ../configure --host=x86_64 --prefix=$CROSS_COMPILE_AREA
#make -j
#make -j install
#popd
#popd

echo "Build MonetDB"
rm -rf monetdb
git clone https://github.com/MonetDB/MonetDB.git monetdb
pushd monetdb
git checkout 19539f3 # semi-arb. commit
popd
#cp $BASE_DIR/CMakeLists.txt monetdb/
#cp $BASE_DIR/monetdb-functions.cmake monetdb/cmake/
mkdir -p monetdb-build
pushd monetdb-build
# Run the build (turn off assertions)
cmake3 \
    -DCMAKE_TOOLCHAIN_FILE=$BUILD_DIR/../linux-riscv-gnu.cmake \
    -DEXTRA_CMAKE_FIND_ROOT_PATH=$CROSS_COMPILE_AREA \
    -DCMAKE_PREFIX_PATH=$CROSS_COMPILE_AREA \
    -DCMAKE_INSTALL_PREFIX=$CROSS_COMPILE_AREA \
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
cmake3 \
    --build . --target install

echo "Testing installation"
ls $CROSS_COMPILE_AREA/bin/monetdb
ls $CROSS_COMPILE_AREA/bin/mserver5

popd
popd

echo "Generate TPC-H Data"
./host-gen-tpch-data.sh $1
