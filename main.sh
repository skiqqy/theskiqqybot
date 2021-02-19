#!/bin/bash
pip3 install --user -r ./deps.txt
gen_key_config () {
	rand_key=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
	cat << EOF > keys
api_id=<id>
api_hash=<hash>
bot_token=<token>
database_encryption_key=$rand_key
EOF
}
[ ! -f keys ] && gen_key_config || echo "keys file found, skipping."
python3 src/main.py
