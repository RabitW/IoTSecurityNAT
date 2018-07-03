#!/bin/bash

# Action script to config device & proxy rules.
#
#
# Author: Rocky
# Date:   2018/04/08
# Description: Has two interface: wlan0 and eth0, no bridge.
#

WorkDir=/opt/IoTSecurityNAT/
ConfDir=/opt/IoTSecurityNAT/CONF/
iInf=eth0
wInf=wlan0


# Config iptable nat PREROUTING rules
function AddRules()
{
# Read SOURCE_IP DPORT PROXY_PORT
echo ""
echo "Config Proxy Rule"
echo "--------------------------------------------------------------------------------------------------"
echo -e "\033[44;37;1m Input Device IP address need to be proxyed: \033[0m"
read SOURCE_IP
echo ""
echo -e "\033[44;37;1m Input Dest port need to be proxyed: \033[0m"
echo "Input nothing: default ports 80 8080 443 8088 3414 1:65535;Input other port need to be proxyed:"
read DPORT
echo ""
echo -e "\033[44;37;1m Input Proxy Ports Redirect to: \033[0m"
echo "Input nothing: default use 9999 as proxy port;"
read PROXY_PORT

# Config iptables nat PREROUTING rules and startup Burpsuite
if [ ""$PROXY_PORT = "" ];then
    PROXY_PORT=9999
    if [ "$DPORT" = "" ];then
        iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 80 -j REDIRECT --to-ports $PROXY_PORT
        iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 8080 -j REDIRECT --to-ports $PROXY_PORT
        iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT
        iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 8088 -j REDIRECT --to-port $PROXY_PORT
        iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 3414 -j REDIRECT --to-port $PROXY_PORT
	iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 1:65535 -j REDIRECT --to-port $PROXY_PORT
    else
        iptables -t nat -I PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport $DPORT -j REDIRECT --to-port $PROXY_PORT
    fi
elif [ "$DPORT" = "" ];then
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 8080 -j REDIRECT --to-ports $PROXY_PORT
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 8088 -j REDIRECT --to-ports $PROXY_PORT
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 443 -j REDIRECT --to-ports $PROXY_PORT
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 3414 -j REDIRECT --to-ports $PROXY_PORT
    iptables -t nat -A PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport 1:65535 -j REDIRECT --to-ports $PROXY_PORT
else
    iptables -t nat -I PREROUTING -i $wInf -s $SOURCE_IP -p tcp --dport $DPORT -j REDIRECT --to-ports $PROXY_PORT
fi;
PROXY_STATUS=`netstat -antp|grep $PROXY_PORT|grep -i listen|wc -l`;
if [ $PROXY_STATUS = 0 ];then
    echo -e "\033[42;37;1m Please config listen port: $PROXY_PORT \033[0m"
    sh -c "java -jar /opt/burpsuite_pro_v1-2/BurpUnlimited.jar >>/dev/null";
fi
echo "--------------------------------------------------------------------------------------------------"
echo ""
}


# Show Device status and iptables nat PREROUTING rules
function ShowStatus()
{
echo ""
echo -e "\033[42;37;1m show device info \033[0m";
arp -a|grep $wInf|grep -v incomplete|awk '{print $2" "$4}'>$WorkDir/ArpList
echo "--------------------------------------------------------------------------------------------------"
printf "| %-25s | %-35s | %-15s | %-10s |\n" Device "IP_Address        MAC_Address" User Comment
echo "--------------------------------------------------------------------------------------------------"
awk 'NR==FNR{a[$2]=$0;next}{printf ("| %-25s | %-35s | %-15s | %-10s |\n",$2,a[$1],$3,$4)}' $WorkDir/ArpList $WorkDir/DeviceInfo
echo "--------------------------------------------------------------------------------------------------"
echo ""
echo -e "\033[42;37;1m show iptables NAT PREROUTING rules \033[0m";
echo "--------------------------------------------------------------------------------------------------"
iptables -t nat -nvL PREROUTING --line-numbers
echo "--------------------------------------------------------------------------------------------------"
echo ""
}


# Clear iptables NAT PREROUTING rules
function ClearRules()
{
echo ""
echo -e "\033[42;37;1m Clear NAT PREROUTING rules \033[0m";
echo "--------------------------------------------------------------------------------------------------"
while :
do
    echo -e "input \033[44;37;1m number \033[0m: Delete rule"
    echo -e "input \033[44;37;1m all    \033[0m: Clear all rules"
    echo -e "input \033[44;37;1m 0      \033[0m: Exit "
    read RULE_NO
    case $RULE_NO in
          all)
		  iptables -t nat -F PREROUTING
		  break
		  ;;
          0)
		break
		;;
	
	([[:digit:]]*)
		iptables -t nat -D PREROUTING $RULE_NO
		continue;
		;;
	*)
		echo -e "\033[42;37;1m Please input rule number \033[0m"
		continue
		;;
	esac
done
echo ""
}


# Add new device
function AddDevice()
{
echo ""
echo -e "\033[42;37;1m Add new device \033[0m"
echo "------------------------------------------------------------------------------------------------"
while :
do
    echo -e "input \033[44;37;1m 1 \033[0m: Show device config"
    echo -e "input \033[44;37;1m 2 \033[0m: Show new device"
    echo -e "input \033[44;37;1m 3 \033[0m: Add new device"
    echo -e "input \033[44;37;1m 0 \033[0m: Exit"
    read DEV_ACTION_NO
    case $DEV_ACTION_NO in
	    1)
		    # show all device 
		    echo -e "\033[42;37;1m device config in file DeviceInfo \033[0m"
		    echo "---------------------------------------------------------------------------------------------"
		    cat $WorkDir/DeviceInfo
		    echo ""
		    echo -e "\033[42;37;1m dhcp config in file dhcphosts \033[0m"
		    echo "---------------------------------------------------------------------------------------------"
		    cat $ConfDir/dhcphosts
		    echo "----------------------------------------------------------------------------------------------"
		    echo ""
		    ;;
	    2)
		    # show new device
		    for DEV_MAC in `arp -a|grep $wInf|grep -v incomplete|awk '{print $4}'`
                       do
                       DEV_IP=`arp -a|grep wlan0|grep -v incomplete|grep "$DEV_MAC"|cut -d ')' -f1|cut -d '(' -f2`
                       MAC_NO=`grep $DEV_MAC $WorkDir/DeviceInfo|grep -v "^#"|wc -l`
                       if [ "$MAC_NO" = "0" ];then
	                  echo -e "Found new device: \033[44;37;1m$DEV_MAC\033[0m  \033[44;37;1m$DEV_IP\033[0m"
                       fi
		    done
		    echo ""
		     ;;
	    3)
		    # add new device to DeviceInfo and dhcphosts
                    for DEV_MAC in `arp -a|grep $wInf|grep -v incomplete|awk '{print $4}'`
			do
			DEV_IP=`arp -a|grep wlan0|grep -v incomplete|grep "$DEV_MAC"|cut -d ')' -f1|cut -d '(' -f2`
			MAC_NO=`grep $DEV_MAC $WorkDir/DeviceInfo|grep -v "^#"|wc -l`
			if [ "$MAC_NO" = "0" ];then
			    echo -e "Found new device: \033[44;37;1m$DEV_MAC\033[0m  \033[44;37;1m$DEV_IP\033[0m"
			    echo -e "Please input device name:"
			    read DEV_NAME
			    echo -e "$DEV_MAC\t$DEV_NAME" >>$WorkDir/DeviceInfo
			    echo -e "$DEV_MAC,$DEV_NAME,$DEV_IP,infinite" >>$ConfDir/dhcphosts
			fi
		    done
                    echo ""
		    ;;
            0)
		     break
		     ;;
            *)
		     echo -e "\033[42;37;1m Please input number 1,2,3,0 \033[0m"
		     continue
		     ;;
    esac
done
echo ""
}


# Main
while :
do
    # Input action number
    echo -e "input \033[36;41;1m 1 \033[0m : Show proxy status"
    echo -e "input \033[36;41;1m 2 \033[0m : Add proxy rules"
    echo -e "input \033[36;41;1m 3 \033[0m : Clear proxy rules"
    echo -e "input \033[36;41;1m 4 \033[0m : Add new device"
    echo -e "input \033[36;41;1m 0 \033[0m : Exit"
    read ACTION_NO
    case $ACTION_NO in
	1)
		ShowStatus;
		;;
	2)
		AddRules;
		;;
	3)
	 	ClearRules;
		;;
	4)
		AddDevice;
		;;
	0)
		exit 4;
		;;
	*)
		continue;
		;;
    esac
done
