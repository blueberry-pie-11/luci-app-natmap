#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# 如果$forward_enable不为1，则直接退出
if [ $FORWARD_ENABLE != 1 ]; then
    exit 0
fi

# 如果$forward_mode为空，则直接退出
if [ -z "$FORWARD_MODE" ]; then
    exit 0
fi

# 如果$forward_natmap_use_natmap为1，则直接退出
if [ "$FORWARD_NATMAP_USE_NATMAP" == "1" ]; then
    exit 0
fi

# 如果$forward_target_port为空或者$forward_target_ip为空则退出
if [ -z "$FORWARD_TARGET_PORT" ] || [ -z "$FORWARD_TARGET_IP" ]; then
    exit 0
fi

case $FORWARD_MODE in
"firewall")
    source /usr/share/natmap/plugin-forward/firewall-forward.sh "$@"
    ;;
"ikuai")
    source /usr/share/natmap/plugin-forward/ikuai-forward.sh "$@"
    ;;
*) ;;
esac
