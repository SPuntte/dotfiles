# In an X environment, load modified keymap
if [ "$DISPLAY" -a -f ~/.Xmodmap ]; then
	xmodmap ~/.Xmodmap
fi
