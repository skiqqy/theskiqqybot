#!/usr/bin/env bash
# Core api/helper functions

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[92m'
NC='\033[0m'

# Display an error message and exit.
# error [message] [exit code]
error()
{
	printf "[ %bERROR%b ] %s\n" "${RED}" "${NC}" "$1"
	exit "${2:-1}"
}

warning()
{
	printf "[ %bWARNING%b ] %s\n" "${YELLOW}" "${NC}" "$1"
}

info()
{
	printf "[ INFO ] %s\n" "$1"
}

success()
{
	printf "[ %bSUCCESS%b ] %s\n" "${GREEN}" "${NC}" "$1"
}

tick()
{
	printf "%s %b✔%b\n" "$1" "${GREEN}" "${NC}"
}

# Usage: debug "Some Text"
# Prints messages if verbose is set
debug () {
	if [ -n "$verbose" ] && [ -n "$1" ]
	then
		printf '%b' "$1"
	fi
}

# Sends a telegram message to the chat_id
# $1: The message we send
send_message()
{
	if [ -z "$reset" ]
	then
		result=$(curl -s -X POST \
			"https://api.telegram.org/bot$bot_token/sendMessage" \
			-d chat_id="$chat_id" \
			-d text="$1")
		debug "$result"
		debug "Sending: $1"
	fi
}

# Prints last unique message
# Returns 0 if success, 1 if no new message
get_newMessage()
{
	touch /tmp/theskiqqybot.msgid
	. /tmp/theskiqqybot.msgid
	declare -g last_update_id
	local offset

	[ -n "$last_update_id" ] && offset="-d $((last_update_id))"
	res=$(curl -s -X POST "https://api.telegram.org/bot$bot_token/getUpdates" \
		-d chat_id="$chat_id" $offset | jq .result[-1]) # I want offset to split
	new_update_id=$(jq .update_id <<< "$res")

	if [ "$new_update_id" = "$last_update_id" ]
	then
		return 1
	else
		jq .message.text <<< "$res" | jq -r . # Strip the surrounding "
		echo "last_update_id=$new_update_id" > /tmp/theskiqqybot.msgid # ty subshells >:(
	fi
}
