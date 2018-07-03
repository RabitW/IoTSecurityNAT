#!/bin/bash

dnslog=/var/log/dnsmasq.log
dnspidfile=/var/run/dnsmasq.pid

# Show DNS Query
function ShowDNS()
{
echo ""
echo "------------------------------------------------"
while :
do
echo -e "input \033[44;37;1m 1 \033[0m: Show dns query"
echo -e "input \033[44;37;1m 2 \033[0m: Show dns reply"
echo -e "input \033[44;37;1m 0 \033[0m: Exit"
read DNS_ACT_NO
case $DNS_ACT_NO in
	1)
		echo ""
		echo "--------------------------------------------------------"
		grep -a "$DeviceIP" $dnslog|grep query|awk '{print $8}'|sort|uniq -c
		echo "--------------------------------------------------------"
		echo ""
		;;
	2)
		echo ""
		echo "--------------------------------------------------------"
		echo -e "\033[42;37;1m Input Server IP or Domaine Name \033[0m"
		read DNS_SEARCH
		echo "--------------------------------------------------------"
		grep -a "$DeviceIP" $dnslog|egrep -a "reply|cache"|grep "$DNS_SEARCH"|awk '{printf ("%5s %20s %50s\n",$7,$10,$8)}'|sort|uniq -c
		echo "--------------------------------------------------------"
		echo ""
		continue
		;;
	0)
		break
		;;
esac
done
echo "------------------------------------------------"
echo ""
}

# Reload DNS hosts file
function ReloadDNS()
{
# When it receives a SIGHUP, dnsmasq clears its cache and then re-loads /etc/hosts and /etc/ethers and any file given by --dhcp-hostsfile, --dhcp-hostsdir, --dhcp-optsfile, --dhcp-optsdir, --addn-hosts or --hostsdir. 
echo ""
echo -e "\033[42;37;1m Reload file \033[0m"
echo "------------------------------------------------"
kill -1 `cat $dnspidfile`
tail -5 $dnslog
echo "------------------------------------------------"
echo ""
}


# Main
while : 
do
	# Input Device IP
	echo -e "input \033[36;41;1m Device IP \033[0m : Dns search"
	echo -e "input \033[36;41;1m     1     \033[0m : Reload dns file"
	echo -e "input \033[36;41;1m     0     \033[0m : Exit"
	echo "---------------------------------------------------------"
	read DeviceIP
	case $DeviceIP in
		0)
			break
			;;
		1)
			ReloadDNS
			;;

		*)
			ShowDNS
			;;
	esac
#	ShowDNS
done
