#!/usr/bin/env bash
# message watcher

# Due to the nature of tg messages, the command is 1 string literal,
# Hence we must do a bit more parsing than usual
# usage: exec_cmd COMMAND
exec_cmd()
{
	info "EXEC: $1"
	case "$1" in
		/help|HELP|help|usage)
			send_message "$(cat "$SCRIPT_DIR/../assets/help")"
			;;
		/status*|status*|/check*|check*) # Wrapper for $ skiqqy check
			all=( git social wiki ) # Shortcut to check all domains
			if [[ "$1" =~ ^/?(status|check)(\t| )*$ ]]
			then
				send_message "$(skiqqy check)"
			else
				while read -r sd
				do
					if [ "$sd" = all ]
					then
						send_message "$(skiqqy check)"
						for sd in ${all[*]} # Yes i am reusing sd
						do
							send_message "$(skiqqy check "$sd")"
						done
					else
						send_message "$(skiqqy check "$sd")"
					fi
				done < <(tr -s ' ' <<< "$1" | cut -d ' ' -f 2- | tr ' ' '\n')
			fi
			;;
		/refresh|refresh)
			send_message 'TODO: Refresh domains'
			;;
		*)
			send_message 'ERR: Unknown command.'
			;;
	esac
}

# Main event loop
# usage: event_loop SLEEP_TIMER
event_loop()
{
	local msg

	for ((;;))
	do
		if msg=$(get_newMessage)
		then
			exec_cmd "$msg"
		fi
		[ -n "$1" ] && sleep "$1"
	done
}

# Debug mode
debug_mode()
{
	SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
	. "$SCRIPT_DIR/core.sh"

	send_message(){ echo "SEND: $1"; }
	get_newMessage(){ read -rp 'Enter Command: ' out && echo "$out"; }

	event_loop
}

main()
{
	get_newMessage > /dev/null # Cache last message, so we dont exec old stuff

	info 'Starting message watcher'

	event_loop 1
}

if [[ "$0" =~ ^.*main\.sh$ ]]
then
	main "$@" # Server mode
else
	debug_mode # enter debug REPL
fi
