#!/bin/bash

# Action script to enable/disable monitor.
#
#
# Author: Rocky
# Date:   2018/04/08
# Description: Has two interface: wlan0 and eth0, no bridge.
#


# Interface that we want to monitor on
WIRELESS_MONITOR_INTERFACE=wlan0
# Interface that is connected to our regular network (e.g. Internet)
INTERNET_INTERFACE=eth0
# Network address range we use for our monitor network (please change IP address in file dnsmasq.conf and dhsphostfile in dir ./CONF/)
MONITOR_NETWORK=10.42.0.0/24
# The address we assign to our router, dhcp, and dns server.
MONITOR_MAIN=10.42.0.1/24
# The dir 
WorkDir=/opt/IoTSecNAT
ConfDir=/opt/IoTSecNAT/CONF

# Start monitor
function startMonitor()
{
	echo ""
	#
	#nmcli radio wifi off;
	#rfkill unblock wlan;

	# bring up the wireless network interface
	ifconfig $WIRELESS_MONITOR_INTERFACE $MONITOR_MAIN;
	ip link set dev $WIRELESS_MONITOR_INTERFACE up;

	# configure it to be an access point 
	echo -e "\033[42;37;1m start hostapd \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	hostapd -B $ConfDir/hostapd.conf;

	# configure our DHCP server (conf-file did not support variable)
	echo -e "\033[42;37;1m start dnsmasq \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	dnsmasq --conf-file=/opt/IoTSecNAT/CONF/dnsmasq.conf;
	tail -20 /var/log/dnsmasq.log;

	# enable ip forward
	sysctl -w net.ipv4.ip_forward=1;

	# clear rules
	iptables -F;
	iptables -X;
	iptables -t nat -F;
	iptables -t nat -X;
	iptables -t mangle -F;
	iptables -t mangle -X;
	# Add rule for traffic from MONITOR towards INTERNET
	/sbin/iptables --table filter --insert INPUT --in-interface $WIRELESS_MONITOR_INTERFACE --protocol tcp --destination-port 53 --jump ACCEPT;
	/sbin/iptables --table filter --insert INPUT --in-interface $WIRELESS_MONITOR_INTERFACE --protocol udp --destination-port 53 --jump ACCEPT;
	/sbin/iptables --table filter --insert INPUT --in-interface $WIRELESS_MONITOR_INTERFACE --protocol tcp --destination-port 67 --jump ACCEPT;
	/sbin/iptables --table filter --insert INPUT --in-interface $WIRELESS_MONITOR_INTERFACE --protocol udp --destination-port 67 --jump ACCEPT;
#	/sbin/iptables --table filter --insert FORWARD --in-interface $WIRELESS_MONITOR_INTERFACE --jump REJECT;
#	/sbin/iptables --table filter --insert FORWARD --out-interface $WIRELESS_MONITOR_INTERFACE --jump REJECT;
	/sbin/iptables --table filter --insert FORWARD --in-interface $WIRELESS_MONITOR_INTERFACE --out-interface $WIRELESS_MONITOR_INTERFACE --jump ACCEPT;
	/sbin/iptables --table filter --insert FORWARD --source $MONITOR_NETWORK --in-interface $WIRELESS_MONITOR_INTERFACE --jump ACCEPT;
	/sbin/iptables --table filter --insert FORWARD --destination $MONITOR_NETWORK --out-interface $WIRELESS_MONITOR_INTERFACE --match state --state ESTABLISHED,RELATED --jump ACCEPT;
	/sbin/iptables --table nat --insert POSTROUTING --source $MONITOR_NETWORK ! --destination $MONITOR_NETWORK --jump MASQUERADE;
	echo "---------------------------------------------------------------------------------------------"
	echo ""
}

# Stop monitor
function stopMonitor()
{
	echo ""
	# clear rules
	iptables -F;
	iptables -X;
	iptables -t nat -F;
	iptables -t nat -X;
	iptables -t mangle -F;
	iptables -t mangle -X;
	# stop HostApd
	echo -e "\033[42;37;1m stop hostapd \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	killall hostapd;
	echo ""
	# stop dnsmasq
	echo -e "\033[42;37;1m stop dnsmasq \033[0m" 
	echo "---------------------------------------------------------------------------------------------"
	killall dnsmasq;	
	tail -5 /var/log/dnsmasq.log
	echo ""
	# Bringing down interfaces
	echo -e "\033[42;37;1m stop interface \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	ifconfig $WIRELESS_MONITOR_INTERFACE down
	echo ""
	echo -e "\033[42;37;1m make the bridge unamnaged \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	nmcli radio wifi off
	rfkill unblock wlan
	echo ""
	echo -e "\033[42;37;1m delete all addresses for wireless \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	ip addr flush dev $WIRELESS_MONITOR_INTERFACE
	echo ""
}

# Show monitor status
function statusMonitor()
{
	echo ""
	echo -e "\033[42;37;1m hostapd status \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	ps aux |grep [h]ostapd|grep -v "grep"
	echo ""
	echo -e "\033[42;37;1m dnsmasq status \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	ps aux |grep [d]nsmasq|grep -v "grep"
	echo ""
	echo -e "\033[42;37;1m iptables rules \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	iptables -L;
	echo ""
	echo -e "\033[42;37;1m iptables NAT rules \033[0m"
	echo "---------------------------------------------------------------------------------------------"
	iptables -t nat -L;
	echo ""
}

# Debug
function debugMonitor()
{
	# input action number
	echo ""
	echo -e "input \033[44;37;1m 1 \033[0m : show hostapd log"
	echo -e "input \033[44;37;1m 2 \033[0m : show dnsmasq log"
	echo -e "input \033[44;37;1m 0 \033[0m : Exit"
	read debugNo
	case $debugNo in
		1)
			echo -e "\033[42;37;1m hostapd log \033[0m"
			echo "--------------------------------------------------------------------------------------------"
			tail -f /var/log/syslog|grep hostapd
			;;
		2)
			echo -e "\033[42;37;1m dnsmasq log \033[0m"
			echo "--------------------------------------------------------------------------------------------"
			tail -f /var/log/dnsmasq.log
			;;
		0)
			break
			;;
		*)
			continue
			;;
	esac

}

# Add peer
function addPeer()
{
# Add route to Seclabiot2
route add -net 10.43.0.0 netmask 255.255.255.0 gw 192.168.31.102
echo ""
echo "Show Route"
echo "--------------------------------------------------------------------------------------------"
netstat -rn
echo ""
#iptables --table nat --insert POSTROUTING --source 10.43.0.0/24 ! --destination 10.42.0.0/24 --jump MASQUERADE
}
while :
do
	# Input action number
	echo "---------------------------------------------------------------------------------------------"
	echo -e "input \033[36;41;1m 1 \033[0m : Show Monitor Status"
	echo -e "input \033[36;41;1m 2 \033[0m : Start Monitor"
	echo -e "input \033[36;41;1m 3 \033[0m : Stop Monitor"
	echo -e "input \033[36;41;1m 4 \033[0m : Debug"
	echo -e "input \033[36;41;1m 5 \033[0m : AddPeer"
	echo -e "input \033[36;41;1m 0 \033[0m : Exit"
	read actionNo
	case $actionNo in
		1)
			statusMonitor;
			;;
		2)
			startMonitor;
			;;
		3)
			stopMonitor;
			;;
		4)
			debugMonitor;
			;;
		5)
			addPeer;
			;;
		0)
			exit 4;
			;;
		*)
			continue;
			;;
	esac
done
