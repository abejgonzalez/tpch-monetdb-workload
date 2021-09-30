#!/bin/bash

set -ex

# Assumption: FireMarshal is already initialized

FM_DIR=$1

# check out submodules
git submodule update --init --recursive

# setup the pystethoscope in buildroot
BUILDROOT_DIR=$FM_DIR/boards/default/distros/br/buildroot
pushd $BUILDROOT_DIR
./util/scanpypi.py monetdb-stethoscope -o package

# add the installed options to the main Config.in
pushd package

sed -i '/^.*python-zope-interface.*/a \\tsource \"package\/python-monetdb-stethoscope\/Config.in\"' Config.in
sed -i '/^.*python-zope-interface.*/a \\tsource \"package\/python-pymonetdb\/Config.in\"' Config.in
sed -i '/^.*python-zope-interface.*/a \\tsource \"package\/python-future\/Config.in\"' Config.in

popd
popd
