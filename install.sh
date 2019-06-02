#!/usr/bin/env bash

set -u

INSTALL_DIR=$HOME
LOCAL_BIN_DIR=$HOME/.local/bin
BACKUP_DIR=$HOME/dotbackup/$(date +%F_%H%M%S)

ALACRITTY_SRC=https://github.com/jwilm/alacritty/releases/download/v0.3.2/Alacritty-v0.3.2-ubuntu_18_04-$(uname -m).tar.gz
OH_MY_ZSH_INSTALL_SRC=https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
PYENV_INSTALL_SRC=https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer

panic() { printf "ERROR: $*\n"; exit 255; }

# Test if given program/command exists
cmd_exists() { command -v $1 &>/dev/null; }

# Check that given commands exist
require() {
	for cmd in $@; do
		if ! cmd_exists $cmd; then
			printf "Missing command: $cmd\n"
			exit 4
		fi
	done
}

# Try to find a package manager
detect_package_manager() {
	if [ ${pm_detected:=0} -ne 0 ]; then
		return 0
	fi
	printf "\tDetecting package manager...\n"
	install_cmd=""
	query_cmd=""
	sudo_cmd=""
	# Try to check if user has sudo rights
	if cmd_exists sudo; then
		if ! (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' \
			>/dev/null; then
			printf "\t\tMissing sudo rights\n"
		else
			sudo_cmd="sudo"
		fi
	else
		printf "\t\tSudo not found in \$PATH"
	fi
	if cmd_exists aptdcon; then
		printf "\t\tFound: aptdcon\n"
		aptdcon -c
		install_cmd="aptdcon -i"
		query_cmd="dpkg -l"
	elif cmd_exists apt; then
		printf "\t\tFound: apt\n"
		$sudo_cmd apt update
		install_cmd="$sudo_cmd apt -y install"
		query_cmd="dpkg -l"
	elif cmd_exists pacman; then
		printf "\t\tFound: pacman\n"
		$sudo_cmd pacman -Sy
		install_cmd="$sudo_cmd pacman --needed --noconfirm -S"
		query_cmd="pacman -Qi"
	else
		printf "\t\tWhat distro is this?! *tips fedora*\n"
		exit 3
	fi
	pm_detected=1
}

do_install() {
	$install_cmd $@
}

is_package_installed() {
	detect_package_manager
	$query_cmd $1 &>/dev/null
}

install_packages() {
	detect_package_manager
	local missing=""
	for pkg in $@; do
		if ! is_package_installed $pkg; then
			missing="$missing $pkg"
		fi
	done
	if [ -z "$missing" ]; then
		return 0
	fi
	# Workaround for aptdcon quotes
	if echo "$install_cmd" | grep aptdcon &> /dev/null; then
		for pkg in $missing; do
			do_install $pkg
		done
	else
		do_install $missing
	fi
}

# Check that chsh can change login shell to given shell
is_shell_available() {
	grep /$1$ /etc/shells &>/dev/null
}

backup_existing_dotfiles() {
	printf "Backing up existing dotfiles...\n"
	# "safe-find" from
	# https://github.com/l0b0/tilde/blob/master/examples/safe-find.sh
	while IFS= read -r -d '' -u 9
	do
		dotfile=${REPLY#./*/}
		testfile=$INSTALL_DIR/$dotfile
		backupfile=$BACKUP_DIR/$dotfile
		if [ -f $testfile ]; then
			printf "\t$dotfile\n"
			mkdir -p $(dirname $backupfile)
			cp $testfile $backupfile
		fi
	done 9< <( find ./*/ -type f -exec printf '%s\0' {} + )
	printf "\tOK\n\n"
}

change_to_zsh() {
	printf "Change login shell to zsh...\n"
	if [ $SHELL != $(which zsh) ]; then
		install_packages zsh
		if ! chsh -s $(grep /zsh$ /etc/shells | tail -1) &>/dev/null; then
			# Anecdotal evidence: some systems list both
			# /bin/zsh and /usr/bin/zsh in /etc/shells but
			# only allow 'chsh - s' to the former.
			if ! chsh -s $(grep /zsh$ /etc/shells | head -1) &>/dev/null; then
				panic "Failed to change login shell."
			fi
		fi
	fi
	printf "\tOK\n\n"
}

configure_git() {
	printf "Configure Git...\n"
	if ! git config -f $INSTALL_DIR/.gitconfig_local_machine \
		--get user.name > /dev/null; then
		printf "\tname: "
		read git_username
		git config -f $INSTALL_DIR/.gitconfig_local_machine \
			user.name "$git_username"
	fi
	if ! git config -f $INSTALL_DIR/.gitconfig_local_machine \
		--get user.email > /dev/null; then
		printf "\temail: "
		read git_email
		git config -f $INSTALL_DIR/.gitconfig_local_machine \
			user.email "$git_email"
	fi
	printf "\tOK\n\n"
}

install_powerline_fonts() {
	if ! ls $HOME/.local/share/fonts | grep "Powerline" &>/dev/null; then
		printf "Install powerline fonts...\n"
		# clone
		git clone -q --depth=1 https://github.com/powerline/fonts.git \
			fonts.tmp
		# install
		cd fonts.tmp
		./install.sh
		# clean-up a bit
		cd ..
		rm -rf fonts.tmp
		printf "\tOK\n\n"
	fi
}

install_alacritty() {
	if cmd_exists alacritty; then
		return 0
	fi
	printf "Install alacritty...\n"
	if ! install_packages alacritty alacritty-terminfo; then
		printf "\tPackage not found in repos, install from GitHub..."
		curl -fsSL $ALACRITTY_SRC -o tmp-alacritty.tar.gz
		tar -xzf tmp-alacritty.tar.gz -C $LOCAL_BIN_DIR
		rm tmp-alacritty.tar.gz
		install_packages xclip
	fi
	printf "\tOK\n\n"
}

install_oh_my_zsh() {
	printf "Install .oh-my-zsh...\n"
	# Modify .oh-my-zsh install script to not start zsh on completion
	curl -fsSL $OH_MY_ZSH_INSTALL_SRC | sed -e '/[[:blank:]]*env zsh -l/d' \
		> install_oh-my-zsh.sh
	rm install_oh-my-zsh.sh

	printf "\t.oh-my-zsh DEFAULT_USER: "
	read zsh_default_user
	search="s/DEFAULT_USER="'"'"[a-zA-Z0-9]*"'"'
	replace="/DEFAULT_USER="'"'"$zsh_default_user"'"'"/"
	sed -i -e $search$replace zsh/.zshrc

	ZSH_CUSTOM_DIR=${ZSH_CUSTOM:-$INSTALL_DIR/.oh-my-zsh/custom}

	# Install zsh-autosuggestions
	printf "\tInstall zsh-autosuggestions\n"
	repo=https://github.com/zsh-users/zsh-autosuggestions.git
	plugin=$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions
	if [ ! -d $plugin ]; then
		git clone -q $repo $plugin
	fi

	# Install zsh-completions
	printf "\tInstall zsh-completions\n"
	repo=https://github.com/zsh-users/zsh-completions.git
	plugin=$ZSH_CUSTOM_DIR/plugins/zsh-completions
	if [ ! -d $plugin ]; then
		git clone -q $repo $plugin
	fi

	# Install zsh-syntax-highlighting
	printf "\tInstall zsh-syntax-highlighting\n"
	repo=https://github.com/zsh-users/zsh-syntax-highlighting.git
	plugin=$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting
	if [ ! -d $plugin ]; then
		git clone -q $repo $plugin
	fi

	printf "\tOK\n\n"
}

install_python_et_al() {
	printf "Install Python3 and friends...\n"
	detect_package_manager
	if echo "$install_cmd" | grep apt &>/dev/null; then
		# Python 3 packages are called 'python3-*' in
		# Debian-based distros
		install_packages python3-pip python3-venv
		if ! pip3 freeze -l | grep pipenv &>/dev/null; then
			pip3 install --user pipenv
		fi
		if [ ! -d $INSTALL_DIR/.pyenv ]; then
			curl -fsSL $PYENV_INSTALL_SRC | bash
			install_packages make build-essential libssl-dev \
				zlib1g-dev libbz2-dev libreadline-dev \
				libsqlite3-dev wget curl llvm libncurses5-dev \
				xz-utils tk-dev libxml2-dev libxmlsec1-dev \
				libffi-dev liblzma-dev libsqlite3-dev
		fi
	elif echo "$install_cmd" | grep pacman &>/dev/null; then
		# Arch default Python is Python 3 and pipenv is in repo
		install_packages python-pipenv pyenv \
			base-devel openssl zlib sqlite
	else
		printf "\t\tWhat distro is this?! *tips fedora*\n"
		exit 3
	fi
	printf "\tOK\n\n"
}

create_symlinks() {
	printf "Create symlinks...\n"
	if contains "$TARGETS" "desktop"; then
		stow -v -t $INSTALL_DIR -R alacritty Xmodmap
	fi
	stow -v -t $INSTALL_DIR -R git tmux zsh
	printf "\tOK\n\n"
}

usage() {
	cat <<-EOF
	Usage: $(basename "$0") TARGET ...

	Valid TARGETs are

	base       Command-line stuff: tmux, zsh, etc.
	desktop    Desktop stuff: Alacritty, Xmodmap; implies 'base'
	python     Python development environment: Python 3, pipenv, pyenv, etc.; implies 'base'
EOF
}

is_valid_target() { echo "base desktop python" | grep -F -q -w "$1"; }

contains() { echo "$1" | grep -F -q -w "$2"; }

main() {
	for target in "$TARGETS"; do
		if ! is_valid_target $target; then
			printf "Unknown target: $target\n"
			exit 2
		fi
	done
	printf "Install target(s): $TARGETS\n\n"
	
	require chsh which
	if ! cmd_exists git; then
		printf "Install Git...\n"
		if ! install_packages git; then
			panic "Git is required and installing it failed."
		fi
		printf "\tOK\n\n"
	fi
	if ! cmd_exists stow; then
		printf "Install GNU stow...\n"
		if ! install_packages stow; then
			panic "GNU stow is required and installing it failed."
		fi
		printf "\tOK\n\n"
	fi

	# TODO: control by variable
	backup_existing_dotfiles
	change_to_zsh
	configure_git
	if contains "$TARGETS" "desktop"; then
		install_powerline_fonts
		install_alacritty
	fi
	install_oh_my_zsh
	install_packages source-highlight
	if contains "$TARGETS" "python"; then
		install_python_et_al
	fi
	create_symlinks
}

if [ $# -eq 0 ]; then
	usage >&2
	exit 1
elif [ $# -eq 1 -a $1 = "-h" ]; then
	usage
	exit 0
else
	TARGETS="$@"
	main "$@"
fi
