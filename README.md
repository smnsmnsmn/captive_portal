A (very) simple evil twin access point captive portal suite. Can also be used as a regular captive portal for simple cases easily.

Make sure you have installed: go, hostapd, dnsmasq, iptables, macchanger

Usage: 
```sh
./portal.sh evil-iface internet-iface ssid
```
*replace evil-iface with the name of your "evil" (mitm) network interface and internet-iface with the name of the original network*
