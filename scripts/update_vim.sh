#!/bin/bash
set -u

WORKDIR=$HOME/pkg/vim
VIM_GIT_URL=https://github.com/vim/vim.git

RPATH=""
for version in $(pyenv global); do
	RPATH="$(pyenv root)/versions/$version/lib:$RPATH"
done
RPATH=${RPATH%?}

if [ ! -d $WORKDIR ]; then
	git clone $VIM_GIT_URL $WORKDIR
fi

cd $WORKDIR
git fetch
git checkout $(git tag -l | tail -n 1)
make distclean

LDFLAGS="-Wl,-rpath=$RPATH" ./configure \
	--prefix=$HOME/.local \
	--enable-fail-if-missing \
	--enable-pythoninterp=dynamic \
	--enable-python3interp=dynamic \
	--with-features=huge \
	&& make -j $(nproc) \
	&& make install
