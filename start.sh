#!/bin/bash
# Author: skiqqy
usage () {
	cat << EOF
./start.sh [options]

h: Help
i: Install Dependencies.
p: Run python based bot.
b: Run bash based bot (default).
v: verbose.
EOF
	exit $1
}

install () {
	pip3 install --user -r ./deps.txt
}

while getopts "hipv" opt
do
	case $opt in
		h)
			usage 0
			;;
		i)
			install
			exit 0
			;;
		p)
			script="python"
			;;
		v)
			verbose=1
			;;
		*)
			exit 2
			;;
	esac
done

gen_key_config () {
	rand_key=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
	cat << EOF > assets/keys
api_id=<id>
api_hash=<hash>
bot_token=<token>
db_key=$rand_key
chat_id=<optional>
EOF
}

[ ! -f ./assets/keys ] && gen_key_config || echo "keys file found, skipping generation."

if [ -z $script ]
then
	[ ! -z $verbose ] && flags=" -v" || flags=
	./src/main.sh $flags
else
	python3 src/main.py
fi
