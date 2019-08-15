#!/bin/bash
set -u

WORKDIR=$HOME/pkg/tmux
TMUX_GIT_URL=https://github.com/vim/vim.git
TMUX_TAG="2.9a"

mkdir -p $(dirname $WORKDIR)
if [ ! -d $WORKDIR ]; then
	git clone $TMUX_GIT_URL $WORKDIR
fi

cd $WORKDIR
git fetch
git checkout $TMUX_TAG
sh autogen.sh
./configure --prefix=$HOME/.local && make -j $(nproc) && make install
