# In an X environment, load modified keymap
if [[ -n $DISPLAY && -f ~/.Xmodmap ]]; then
	xmodmap ~/.Xmodmap
fi
