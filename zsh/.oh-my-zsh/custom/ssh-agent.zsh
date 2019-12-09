# From https://gist.github.com/mzedeler/45ef2be24d9ff13b33ba

# Set up ssh-agent
SSH_ENV="$HOME/.ssh/environment"
SSH_LOCAL_ENV="${SSH_ENV}-$(hostname --fqdn)"

function start_agent {
	echo "Initializing new SSH agent..."
	touch $SSH_LOCAL_ENV
	chmod 600 "${SSH_LOCAL_ENV}"
	/usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_LOCAL_ENV}"
	cp -f "${SSH_LOCAL_ENV}" "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
	/usr/bin/ssh-add $HOME/.ssh/id_*[^.pub]
}

# Source SSH settings, if applicable
if [ -f "${SSH_LOCAL_ENV}" ]; then
	cp -f "${SSH_LOCAL_ENV}" "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
	kill -0 $SSH_AGENT_PID 2>/dev/null || {
		start_agent
	}
else
	start_agent
fi
