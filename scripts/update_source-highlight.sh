#!/bin/bash
set -u

WORKDIR=$HOME/pkg/src-hilite
SRC_HILITE_GIT_URL=git://git.savannah.gnu.org/src-highlite.git
SRC_HILITE_TAG="rel_3_1_9"

mkdir -p $(dirname $WORKDIR)

is_first_install=0
if [ ! -d $WORKDIR ]; then
	is_first_install=1
	git clone $SRC_HILITE_GIT_URL $WORKDIR
fi

cd $WORKDIR

if [ "$is_first_install" -ne 1 ]; then
	git fetch
	head_hash="$(git rev-parse HEAD)"
	tag_hash="$(git rev-parse ${SRC_HILITE_TAG}^{})"
	if [ "$head_hash" = "$tag_hash" ]; then
		echo "Already up to date"
		exit 0
	fi
fi

git checkout $SRC_HILITE_TAG || exit $?
autoreconf -i && ./configure --prefix=$HOME/.local && make -j $(nproc) && make install
