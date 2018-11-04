#!/bin/bash

while getopts hc: option
do
case "${option}"
in
h) HELP="1";;
c) CONFIGFILE=${OPTARG};;
esac
done

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ -z "$CONFIGFILE" ] || [ "$HELP" == "1" ]; then
	echo "Usage: $0 -c <configfile>"
	exit 0
fi

if [ ! -f "$CONFIGFILE" ]; then
	echo "Could not read configfile"
	exit 1
fi

source $CONFIGFILE

function dnsfetch {
	matchstring=";; ANSWER SECTION"
	aresult=`dig $domainname a @$dnsserver | grep "$matchstring" -A1 | grep -v "$matchstring"`
	ipaddress=`echo o$aresult | cut -d "A" -f 2`
	echo "${ipaddress}" > dnscache
	return 0
}

function pushpubkey {
	if [ ! -f "${sshkey}.pub" ]; then
		echo "MISSING ${sshkey}.pub"
		return 1
	fi

	ssh-copy-id -i "${sshkey}.pub" "${username}@${domainname}"
	result=$?
	if [ $result -eq 1 ]; then
		echo "Could not insert the key for some reason"
		return 1
	fi
	echo "Key is installed."
	echo "Please consider restricting commands for the key on the remote server."
	echo ""
	echo "Command to prepend to public key"
	echo "COMMAND=\"cat ${tunnel_remoteside_port_file}\""
	return 0
}

function checkfortunnel {
	showmessage "Checking for tunnel"
	dnsfetch
	if [ $? -ne 0 ]; then
		showmessage "Could not update DNS for ${domainname} trough ${dnsserver}"
		return 1
	fi
	ipnumber=`cat dnscache | xargs` 

	portnum=`ssh "${username}@${ipnumber}" -i ${sshkey} "cat ${tunnel_remoteside_port_file}"`

	lockfile="/tmp/tbm_${ipnumber}.lock"
	if [ ! -f "$lockfile" ]; then
		showmessage "Tunnel is down"
		if [ $portnum -lt 1024 ]; then
			showmessage "Tunnel Should be down"
			return 0
		fi
		ssh -R 0.0.0.0:$portnum:$tunnel_localside_ip:$tunnel_localside_port -i $sshkey $username@$ipnumber -N &
		sshpid=$!
		echo "${sshpid}:${portnum}" > $lockfile
		showmessage "Tunnel is started. Remote port ${portnum} points to local $tunnel_localside_ip:$tunnel_localside_port and is running on pid ${sshpid}"
	else
		showmessage "Tunnel is up"
		pid=`cat $lockfile | cut -d ":" -f 1`
		remoteport=`cat $lockfile | cut -d ":" -f 2`
		if [ $portnum -lt 1024 ]; then
			showmessage "Tunnel should be down"
			killtunnel $pid $lockfile
			return 0
		fi

		if [ $portnum -ne $remoteport ]; then
			showmessage "Remote requests new port, restarting tunnel"
			killtunnel $pid $lockfile
			checkfortunnel
			return 0
		fi

		showmessage "Tunnel should stay up"
		showmessage "Tunnel is up on ${pid}"

		# VERIFY PID IS RUNNING
		kill -0 $pid 2> /dev/null
		if [ $? -ne 0 ]; then
			showmessage "PID was not active"
			killtunnel $pid $lockfile
			checkfortunnel
			return 0
		fi
	fi
}

function killtunnel {
	kill $1 2> /dev/null
	rm $2
	showmessage "Killed $1 and removed $2"
	return 0
}

function showmessage {
	if [ "$output_log" -eq 1 ]; then
		now=`date "+%Y-%m-%d %H:%M:%S"`
		echo "$now $1" >> $logfile
	fi

	if [ "$output_console" -eq 1 ]; then
		echo $1
	fi
}

checkfortunnel
