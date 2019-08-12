DEFAULT_TMUX_SESSION=$HOST

tmn_attach() {
	tmux has-session -t $DEFAULT_TMUX_SESSION &> /dev/null && tmux a -t $DEFAULT_TMUX_SESSION || tmux new -s $DEFAULT_TMUX_SESSION
}

tmn() {
	tmux detach -E "tmux has-session -t $DEFAULT_TMUX_SESSION &> /dev/null && tmux a -t $DEFAULT_TMUX_SESSION || tmux new -s $DEFAULT_TMUX_SESSION" &> /dev/null || tmn_attach
}
