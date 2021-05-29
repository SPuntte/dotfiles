# POSIXly store all set options
_oldopts="$(set +o); set -$-"
set -u

STATS_DIR=$HOME/.loginout
echo "$(date --iso-8601=seconds) $LOGINOUT_STATS_SESSNAME $LOGINOUT_STATS_SESSID logout" >> $STATS_DIR/stats
unset LOGINOUT_STATS_SESSNAME LOGINOUT_STATS_SESSID STATS_DIR

# Restore stored options
set +vx; eval "$_oldopts"
unset _oldopts
