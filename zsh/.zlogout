# Keep log-in/out statistics, exculding tmux sessions
STATS_DIR=$HOME/.loginout
if [ -z "$TMUX" ]; then
	echo "$(date --iso-8601=seconds) $(cat $STATS_DIR/.sessname) $(cat $STATS_DIR/.sessid) logout" >> $STATS_DIR/stats
	rm -f $STATS_DIR/.sessname $STATS_DIR/.sessid
fi
