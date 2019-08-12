tmn_attach() {
	tmux has-session -t $HOST &> /dev/null && tmux a -t $HOST || tmux new -s $HOST
}

tmn() {
	tmux detach -E "tmux has-session -t $HOST &> /dev/null && tmux a -t $HOST || tmux new -s $HOST" &> /dev/null || tmn_attach
}
