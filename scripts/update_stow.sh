#!/bin/bash
set -u

STOW_VERSION=2.3.1
WORKDIR=$HOME/pkg/stow-$STOW_VERSION
STOW_FTP_URL=ftp://ftp.funet.fi/pub/gnu/prep/stow/stow-$STOW_VERSION.tar.bz2

mkdir -p $(dirname $WORKDIR)
if [ ! -d $WORKDIR ]; then
	cd $(dirname $WORKDIR)
	wget $STOW_FTP_URL
	wget $STOW_FTP_URL.sig
	gpg2 --verify stow-$STOW_VERSION.tar.bz2.sig || exit $?
	tar -xjf stow-$STOW_VERSION.tar.bz2 
fi

cd $WORKDIR
./configure --prefix=$HOME/.local && make -j $(nproc) && make install
