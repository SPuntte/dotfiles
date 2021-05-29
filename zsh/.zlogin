# POSIXly store all set options
_oldopts="$(set +o); set -$-"
set -u

STATS_DIR=$HOME/.loginout
mkdir -p $STATS_DIR
export LOGINOUT_STATS_SESSID="${$(dd if=/dev/urandom bs=64 count=1 status=none | sha256sum -b)%% *}"
export LOGINOUT_STATS_SESSNAME="$(whoami)@$(hostname)"
echo "$(date --iso-8601=seconds) $LOGINOUT_STATS_SESSNAME $LOGINOUT_STATS_SESSID login" >> $STATS_DIR/stats
unset STATS_DIR

# Restore stored options
set +vx; eval "$_oldopts"
unset _oldopts
