#!/bin/bash
set -u

WORKDIR=$HOME/pkg/tmux
TMUX_GIT_URL=https://github.com/tmux/tmux.git
TMUX_TAG="3.0a"

mkdir -p $(dirname $WORKDIR)

is_first_install=0
if [ ! -d $WORKDIR ]; then
	is_first_install=1
	git clone $TMUX_GIT_URL $WORKDIR
fi

cd $WORKDIR

if [ "$is_first_install" -ne 1 ]; then
	git fetch
	head_hash="$(git rev-parse HEAD)"
	tag_hash="$(git rev-parse ${TMUX_TAG}^{})"
	if [ "$head_hash" = "$tag_hash" ]; then
		echo "Already up to date"
		exit 0
	fi
fi

git checkout $TMUX_TAG || exit $?
sh autogen.sh && ./configure --prefix=$HOME/.local && make -j $(nproc) && make install
