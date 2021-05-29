pathmunge () {
	if ! [ -d "$1" ]; then
		echo "Excluding nonexistent path \'$1\' from PATH"
		return
	fi
	case ":${PATH}:" in
		*:"$1":*)
			;;
		*)
			[ ! -d "$1" ] && return
			if [ "$2" = "after" ] ; then
				PATH=$PATH:$1
			else
				PATH=$1:$PATH
			fi
	esac
}

# Setup PATH et al.

#   Rust/cargo
pathmunge "$HOME/.cargo/bin"

#   ~/.local "prefix"
pathmunge "$HOME/.local/bin"
export LD_LIBRARY_PATH=$HOME/.local/lib
export PKG_CONFIG_PATH=$HOME/.local/pkgconfig

#   pyenv
export PYENV_ROOT="$HOME/.pyenv"
pathmunge "$PYENV_ROOT/bin"

unset pathmunge
export PATH

# pyenv again
eval "$(pyenv init --path)"

export SUDO_EDITOR=rvim
export SYSTEMD_EDITOR=rvim
export EDITOR=vim
