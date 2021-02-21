#!/bin/bash
# Auther: Skiqqy
# This script checks on my web server and sends a telegram message if it is down.

# Vars
domain="skiqqy.xyz"
subd=( api git irc proj blog wiki files social music dev )
SLEEP=60
DOWNC=5 # What we consider to be an unacceptable amount of down domains warrenting a message.
# End vars

usage () {
	cat << EOF
./main.sh [options]

h: Help
v: verbose
EOF
	exit $1
}

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

SCRIPT_PATH=$(dirname $0)
. "$SCRIPT_PATH/alert.sh" > /dev/null 2>&1
[ ! $(command -v error) ] && echo "[WARNING] Missing 'error.sh' import."

# Usage: debug "Some Text"
# Prints messages if verbose is set
debug () {
	if [ ! -z $verbose ]
	then
		echo -e $1
	fi
}

http_code () {
	echo $(curl -s -o /dev/null -w "%{http_code}" $1)
}

# Sends a telegram message to the chat_id
# $1: The message we send
send_message () {
	if [ -z $reset ]
	then
		result=$(curl -s -X POST https://api.telegram.org/bot$bot_token/sendMessage -d chat_id=$chat_id -d text="$1")
		reset=0
		debug $result
		debug "Sending: $1"
	fi
}

while IFS== read -r key val
do
	case $key in
		"api_id")
			api_id=$val
			;;
		"api_hash")
			api_hash=$val
			;;
		"bot_token")
			bot_token=$val
			;;
		"database_encryption_key")
			db_key=$val
			;;
		"chat_id")
			chat_id=$val
			;;
		*)
			echo "Invalid key=$key"
			;;
	esac
done < "$SCRIPT_PATH/../assets/keys"

if [ -z $api_id ] || [ -z $api_hash ] || [ -z $bot_token ] || [ -z $db_key ] || [ -z $chat_id ]
then
	error "Invalid keys file" 1
fi

send_message "Server Watcher has started up."
reset=

for ((;;))
do
	debug "\nRestart main event loop."
	code=$(http_code https://$domain)
	down=()
	downc=0
	if [ "$code" -eq 200 ]
	then
		for sub in ${subd[@]}
		do
			code=$(http_code "https://$sub.$domain")
			debug "checking $sub.$domain = $code"
			if [ ! "$code" -eq 200 ]
			then
				# We take note that this domain is down.
				downc=$(( downc + 1 ))
				down+=( "$sub.$domain" )
			fi
		done
		down="${down[@]}"

		# Check to see if the # of downed domains warrents an msg.
		if [ "$downc" -ge $DOWNC ]
		then
			send_message "Server Warning Catastrophic: The following domains are down -> $down"
			warning "Domains: ${down[@]} are down."
		else
			reset=
		fi
		debug "Finished checking subdomains."
	else
		warning "$domain is down"
		send_message "Server Warning: $domain is down."
	fi
	sleep $SLEEP
done

