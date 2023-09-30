#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

if [ ! -z $FORWARD_USE_NATMAP ] && [ $FORWARD_USE_NATMAP = '1' ]; then
	exit 0
fi

if [ -z "$FORWARD_PORT" ]; then
	exit 0
fi

if [ -z "$FORWARD_TARGET" ]; then
	exit 0
fi

source /usr/lib/natmap/plugin-forward/natmap-forward.sh "$@"
