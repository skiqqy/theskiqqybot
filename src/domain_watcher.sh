#!/usr/bin/env bash
# Domain watcher
# TODO. Tidy up

http_code () {
	curl -s -o /dev/null -w "%{http_code}" "$1"
}

main()
{
	info 'Starting domain watcher'
	domain="skiqqy.xyz"
	subd=( git blog wiki social )
	SLEEP=60
	DOWNC=1
	reset=

	for ((;;))
	do
		debug "\nRestart main event loop."
		code=$(http_code https://$domain)
		down=()
		downc=0
		if [ "$code" -eq 200 ]
		then
			for sub in ${subd[*]}
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

			# Check to see if the # of downed domains warrents an msg.
			if [ "$downc" -ge $DOWNC ]
			then
				send_message \
				"Server Warning: The following domains are down -> ${down[*]}"
				warning "Domains: ${down[*]} are down."
			else
				reset=
			fi
			debug "Finished checking subdomains."
		else
			warning "$domain is down"
			send_message "Server Warning: $domain is down."
		fi
		sleep "$SLEEP"
	done
}

main "$@"
