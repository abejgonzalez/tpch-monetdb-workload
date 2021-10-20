#!/bin/bash

set -ex

tarball_install() {
    sudo yum install -y https://dev.monetdb.org/downloads/epel/MonetDB-release-epel.noarch.rpm
    sudo yum install -y MonetDB-SQL-server5 MonetDB-client
}

full_opt_install() {
    BASE_DIR=$PWD
    BUILD_DIR=$PWD/build-area

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
        -DCMAKE_TOOLCHAIN_FILE=$BUILD_DIR/monetdb/cmake/Toolchains/linux-clang.cmake \
        -DRELEASE_VERSION=ON \
        -DTESTING=OFF \
        -DCMAKE_SUMMARY=ON \
        -DASSERT=OFF \
        -DSTRICT=OFF \
        -DCMAKE_UNITTESTS=OFF \
        ../monetdb
    cmake3 \
        --build . --verbose
    sudo cmake3 \
        --build . --target install

    popd
    popd
}

riscv_like_install() {
    BASE_DIR=$PWD
    BUILD_DIR=$PWD/build-area

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
    # Add this to use Clang w/ all extensions enabled
    #    -DCMAKE_TOOLCHAIN_FILE=$BUILD_DIR/monetdb/cmake/Toolchains/linux-clang.cmake \
    # Add this to use GCC w/ all extensions (other than SSE) disabled
    #    -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/linux-gnu.cmake \
    cmake3 \
        -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/linux-gnu.cmake \
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
    sudo cmake3 \
        --build . --target install

    popd
    popd
}

# update packages
sudo yum update -y

echo "Install required packages"
sudo yum install -y bison cmake cmake3 openssl-devel pkgconf python3 git

echo "Install recommended packages"
sudo yum install -y bzip2-devel libuuid-devel pcre-devel readline-devel xz-devel zlib-devel

sudo yum install -y centos-release-scl

echo "Install most recent devtoolset"
sudo yum install -y devtoolset-10
source /opt/rh/devtoolset-10/enable

echo "Install clang"
sudo yum install -y llvm-toolset-7
source /opt/rh/llvm-toolset-7/enable

#tarball_install
#full_opt_install
riscv_like_install

sudo pip3 install -U monetdb-stethoscope

echo "Testing installation"
which monetdb
which mserver5
which stethoscope
