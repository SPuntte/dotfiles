#!/bin/bash
set -u

WORKDIR=$HOME/pkg/libevent
LIBEVENT_GIT_URL=https://github.com/libevent/libevent.git
LIBEVENT_TAG="release-2.1.11-stable"

mkdir -p $(dirname $WORKDIR)

is_first_install=0
if [ ! -d $WORKDIR ]; then
	is_first_install=1
	git clone $LIBEVENT_GIT_URL $WORKDIR
fi

cd $WORKDIR

if [ "$is_first_install" -ne 1 ]; then
	git fetch
	head_hash="$(git rev-parse HEAD)"
	tag_hash="$(git rev-parse ${LIBEVENT_TAG}^{})"
	if [ "$head_hash" = "$tag_hash" ]; then
		echo "Already up to date"
		exit 0
	fi
fi

git checkout $LIBEVENT_TAG || exit $?
sh autogen.sh && ./configure --prefix=$HOME/.local && make -j $(nproc) && make install
