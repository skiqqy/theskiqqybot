#!/bin/bash
# Auther: Skiqqy
# This script checks on my web server and sends a telegram message if it is down.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
. "$SCRIPT_DIR/core.sh"

usage () {
	cat << EOF
./main.sh [options]

h: Help
v: verbose
EOF
	exit $1
}

# Gracefully die, and kill forked processes, todo. make thread safe
die()
{
	for proc in ${forks[*]}
	do
		info "Killing $proc..."
		kill "$proc"
	done
	exit
}

main()
{
	forks=( )
	while getopts "hv" opt
	do
		case $opt in
			h)
				usage 0
				;;
			v)
				verbose=1
				;;
			*)
				exit 2
				;;
		esac
	done
	shift $((OPTIND-1)) # Get rid of parsed args

	trap die SIGINT SIGTERM
	[ -f "$SCRIPT_DIR/../assets/keys" ] && . "$SCRIPT_DIR/../assets/keys" || exit 1

	if [ -z $api_id ] || [ -z $api_hash ] || [ -z $bot_token ] || \
		[ -z $db_key ] || [ -z $chat_id ]
	then
		error "Invalid keys file" 1
	fi

	info 'Keys Loaded'
	send_message 'TSB Has started :)'
	# Spawn our processes

	. "$SCRIPT_DIR/message_watcher.sh" &
	forks+=( "$!" )

	. "$SCRIPT_DIR/domain_watcher.sh" &
	forks+=( "$!" )

	info "Forked thread PIDs: ${forks[*]}"
	# No op, this is just to easily kill everything
	for ((;;))
	do
		:
	done
}

main "$@"
