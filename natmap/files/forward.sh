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

if [ -z "$FORWARD_TARGET_PORT" ] || [ -z "$FORWARD_TARGET_IP" ]; then
    exit 0
fi

case $FORWARD_MODE in
"local")
    source /usr/lib/natmap/plugin-forward/natmap-forward.sh "$@"
    ;;
"ikuai")
    source /usr/lib/natmap/plugin-forward/ikuai-forward.sh "$@"
    ;;
esac
