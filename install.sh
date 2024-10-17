#!/bin/sh

BUILDROOT=buildroot-2024.08
BUILDROOT_PKG=buildroot-2024.08.tar.gz
BR_TRAINING=$PWD
OUTPUT=$PWD/output

if [ -e /etc/os-release ]; then
  . /etc/os-release
fi
# install debian pkg
if [ ! -e $BR_TRAINING/.install_pkg ]; then
  if [ "$ID" = "debian" ]; then
    sudo apt install build-essential unzip rsync bc libncurses-dev
    touch $BR_TRAINING/.install_pkg
  fi
fi
cd $BR_TRAINING
if [ ! -e $BUILDROOT_PKG ]; then
  wget http://buildroot.org/downloads/$BUILDROOT_PKG
fi

if [ ! -d /opt/$BUILDROOT ]; then
  cd /opt
  sudo tar -xf $BR_TRAINING/$BUILDROOT_PKG
  sudo mkdir $BUILDROOT/dl
  sudo chmod a+w $BUILDROOT/dl
  cd -
fi

if [ ! -d $OUTPUT ]; then
  make -C /opt/$BUILDROOT O=$OUTPUT BR2_EXTERNAL=$BR_TRAINING training_rpi3_defconfig
fi
cd $OUTPUT
make

