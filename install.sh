set -u

TARGET=${1:-"headless"}
INSTALL_DIR=$HOME
LOCAL_BIN_DIR=$HOME/.local/bin
BACKUP_DIR=$HOME/dotbackup/$(date +%F_%H%M%S)

ALACRITTY_SRC=https://github.com/jwilm/alacritty/releases/download/v0.3.2/Alacritty-v0.3.2-ubuntu_18_04-$(uname -m).tar.gz
OH_MY_ZSH_INSTALL_SRC=https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh

panic() {
	printf "ERROR: $*\n"
	exit 255
}

# Test if given program/command exists
cmd_exists() {
	command -v $1 &>/dev/null
}

# Check that given commands exist
require() {
	for cmd in $@; do
		if ! cmd_exists $cmd; then
			printf "Missing command: $cmd\n"
			exit 2
		fi
	done
}

# Try to find a package manager
detect_package_manager() {
	install_cmd_prefix=""
	install_cmd_suffix=""
	sudo_cmd=""
	# Try to check if user has sudo rights
	if cmd_exists sudo; then
		if ! (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' \
			>/dev/null; then
			printf "Missing sudo rights\n"
		else
			sudo_cmd="sudo"
		fi
	else
		printf "sudo not found in \$PATH"
	fi
	if cmd_exists aptdcon; then
		printf "aptdcon found\n"
		aptdcon -c
		install_cmd_prefix="aptdcon --install=\'"
		isntall_cmd_suffix="\'"
	elif cmd_exists apt; then
		printf "apt found\n"
		$sudo_cmd apt update
		install_cmd_prefix="$sudo_cmd apt -y install "
	elif cmd_exists pacman; then
		printf "pacman found\n"
		$sudo_cmd pacman -Sy
		install_cmd_prefix="$sudo_cmd pacman --needed --noconfirm -S "
	else
		printf "What distro is this?! [tips fedora]\n"
		exit 3
	fi
}

install() {
	$install_cmd_prefix$@$install_cmd_suffix
}

try_install() {
	if [ ${pm_detected:=0} -eq 0 ]; then
		detect_package_manager
		pm_detected=1
	fi
	install $@
}

# Check that chsh can change login shell to given shell
is_shell_available() {
	grep "\b$1\b" /etc/shells &>/dev/null
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
			rm -f $testfile
		fi
	done 9< <( find ./*/ -type f -exec printf '%s\0' {} + )
	printf "\tOK\n\n"
}

change_to_zsh() {
	printf "Change login shell to zsh...\n"
	if [ $SHELL != $(which zsh) ]; then
		if ! is_shell_available zsh; then
			try_install zsh
		fi
		chsh -s $(which zsh)
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
	if ! try_install alacritty alacritty-terminfo; then
		curl -fsSL $ALACRITTY_SRC -o tmp-alacritty.tar.gz
		tar -xzf tmp-alacritty.tar.gz -C $LOCAL_BIN_DIR
		rm tmp-alacritty.tar.gz
	fi
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
	rm -rf $plugin
	git clone -q $repo $plugin

	# Install zsh-completions
	printf "\tInstall zsh-completions\n"
	repo=https://github.com/zsh-users/zsh-completions.git
	plugin=$ZSH_CUSTOM_DIR/plugins/zsh-completions
	rm -rf $plugin
	git clone -q $repo $plugin

	# Install zsh-syntax-highlighting
	printf "\tInstall zsh-syntax-highlighting\n"
	repo=https://github.com/zsh-users/zsh-syntax-highlighting.git
	plugin=$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting
	rm -rf $plugin
	git clone -q $repo $plugin
	printf "\tOK\n\n"
}

create_symlinks() {
	printf "Create symlinks...\n"
	if [ "$TARGET" = "desktop" ]; then
		stow -v -t $INSTALL_DIR -R alacritty
	fi
	stow -v -t $INSTALL_DIR -R git tmux vim zsh
	printf "\tOK\n\n"
}

main() {
	if [ "$TARGET" = "headless" ]; then :
	elif [ "$TARGET" = "desktop" ]; then :
	else
		printf "Unknown target: $TARGET\n"
		exit 1
	fi
	printf "Install target: $TARGET\n\n"
	
	require chsh grep which
	if ! cmd_exists git; then
		printf "Install Git...\n"
		if ! try_install git; then
			panic "Git is required and installing it failed."
		fi
		printf "\tOK\n\n"
	fi
	if ! cmd_exists stow; then
		printf "Install GNU stow...\n"
		if !try_install stow; then
			panix "GNU stow is required and installing it failed."
		fi
		printf "\tOK\n\n"
	fi

	# TODO: control by variable
	backup_existing_dotfiles
	change_to_zsh
	configure_git
	if [ "$TARGET" = "desktop" ]; then
		install_powerline_fonts
		install_alacritty
	fi
	install_oh_my_zsh
	create_symlinks
}

main
