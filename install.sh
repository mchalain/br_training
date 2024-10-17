#!/bin/sh

BUILDROOT=buildroot
BUILDROOT_PKG=buildroot-2024.02.6
INSTALLDIR=$PWD
wget http://buildroot.org/downloads/$BUILDROOT_PKG.tar.gz

pushd /opt
tar -xf $INSTALLDIR/$BUILDROOT_PKG.tar.gz
chmod a+w $BUILDROOT/dl
popd

make -C /opt/$BUILDROOT O=$PWD/output BR2_EXTERNAL=$PWD training_rpi3_defconfig
cd output
make
