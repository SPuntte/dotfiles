# Keep log-in/out statistics, exculding tmux sessions
STATS_DIR=$HOME/.loginout
if [ -z "$TMUX" ]; then
	mkdir -p $STATS_DIR
	echo "${$(dd if=/dev/urandom bs=64 count=1 status=none | sha256sum -b)%% *}" > $STATS_DIR/.sessid
	chmod 400 $STATS_DIR/.sessid
	echo "$(whoami)@$(hostname)" > $STATS_DIR/.sessname
	chmod 400 $STATS_DIR/.sessname
	echo "$(date --iso-8601=seconds) $(cat $STATS_DIR/.sessname) $(cat $STATS_DIR/.sessid) login" >> $STATS_DIR/stats
fi
