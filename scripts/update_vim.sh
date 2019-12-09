#!/bin/bash
set -ue

WORKDIR=$HOME/pkg/vim
VIM_GIT_URL=https://github.com/vim/vim.git

RPATH=""
for version in $(pyenv global); do
	RPATH="$(pyenv root)/versions/$version/lib:$RPATH"
done
RPATH=${RPATH%?}

mkdir -p $(dirname $WORKDIR)

is_first_install=0
if [ ! -d $WORKDIR ]; then
	is_first_install=1
	git clone $VIM_GIT_URL $WORKDIR
fi

cd $WORKDIR

if [ "$is_first_install" -ne 1 ]; then
	git fetch
	head_hash="$(git rev-parse HEAD)"
	latest_tag_hash="$(git rev-parse $(git tag | tail -n 1)^{})"
	if [ "$head_hash" = "$latest_tag_hash" ]; then
		echo "Already up to date"
		exit 0
	fi
fi

git checkout $(git tag -l | tail -n 1)
make distclean

LDFLAGS="-Wl,-rpath=$RPATH" ./configure \
	--prefix=$HOME/.local \
	--enable-fail-if-missing \
	--enable-python3interp=dynamic \
	--with-features=huge \
	&& make -j $(nproc) \
	&& make install
