#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

if [ $FORWARD_ENABLE != 1 ]; then
	exit 0
fi

if [ -z "$FORWARD_MODE" ]; then
	exit 0
fi

if [ $FORWARD_USE_NATMAP == 1 ]; then
	exit 0
fi

if [ -z "$FORWARD_PORT" ] || [ -z "$FORWARD_TARGET" ]; then
	exit 0
fi

if [$FORWARD_MODE = 'local']; then
	source /usr/lib/natmap/plugin-forward/natmap-forward.sh "$@"
fi
if [$FORWARD_MODE = 'ikuai']; then
	source /usr/lib/natmap/plugin-forward/ikuai-forward.sh "$@"
fi
