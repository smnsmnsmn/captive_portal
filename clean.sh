#!/bin/bash

killall dnsmasq
killall hostapd
sysctl net.ipv4.ip_forward=0
