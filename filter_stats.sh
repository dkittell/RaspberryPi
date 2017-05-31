#!/bin/sh

#  Pi-Hole Statistics
#
#
#  Created by David Kittell on 3/21/17.
#

clear

# Install Prerequisites - Start
# Install JQ
# sudo apt-get install jq
# Install IPCalc
# sudo apt-get install ipcalc
# Install Network Manager (nmcli)
# sudo apt-get install network-manager
# Install Prerequisites - Stop

# Variables - Start

# All Network Adapters
NetworkPorts=$(ip link show | grep '^[a-z0-9]' | awk -F : '{print $2}')
#echo $NetworkPorts

uptimeFormatted=$(uptime | sed 's|,||' | awk '{sub(":", " hours, ", $3); print "Uptime: " $3 " minutes"}')

json=$(curl -s -X GET http://127.0.0.1/admin/api.php?summaryRaw)
#echo ${json}
#uptime=$(echo ${json} | jq ".server_up_time" | sed 's/"//g')
domains=$(echo ${json} | jq ".domains_being_blocked")
queries=$(echo ${json} | jq ".dns_queries_today")
blocked=$(echo ${json} | jq ".ads_blocked_today")
percentage=$(printf "%0.2f\n" $(echo ${json} | jq ".ads_percentage_today"))
# Variables - Stop

#lsb_release -a
OS=$(lsb_release -i | cut -d ":" -f2 | tr -d '[:space:]')
OSCode=$(lsb_release -c | cut -d ":" -f2 | tr -d '[:space:]')
OSVer=$(lsb_release -r | cut -d ":" -f2 | tr -d '[:space:]')
#echo "$OS $OSCode $OSVer"


echo "$OS $OSCode $OSVer"
echo "    Hostname:                $(hostname)"
#echo "    System Uptime:           $(uptime | awk -F'( |,|:)+' '{print $6,$7",",$8,"hours,",$9,"minutes."}')"
echo "    System Uptime:           $uptimeFormatted"
echo "Network Information"
for val in $(echo $NetworkPorts); do   # Get for all available hardware ports their status
case $val in
"lo"):
;;
*)
#echo $val
#netAdapter=$(nmcli device status | grep $val  | cut -d " " -f1)
#echo $netAdapter
netIP=$(/sbin/ip -o -4 addr list $val | awk '{print $4}' | cut -d/ -f1)
#echo $netIP

netMask=$(ifconfig "$val" | sed -rn '2s/ .*:(.*)$/\1/p')
netCIDR=$(ipcalc $netIP/$val | grep "Netmask:" | cut -d "=" -f2 | cut -d " " -f2 | tr -d '[:space:]')
netWork=$(ipcalc $netIP/$val | grep "Network:" | cut -d "/" -f1 | cut -d " " -f4 | tr -d '[:space:]')

echo "    Adapter:                 $val"
echo "    IP:                      $netIP"
echo "    Netmask:                 $netMask"
echo "    CIDR:                    $netWork/$netCIDR"
echo " "
;;
esac

done
echo "-----------------------------------------------------------------------"
echo "Ad Filter Stats"
echo "    Total Blocked Hosts:     ${domains}"
echo "    Total Queries:           ${queries}"
echo "    Total Blocked:           ${blocked} (${percentage}%)"
