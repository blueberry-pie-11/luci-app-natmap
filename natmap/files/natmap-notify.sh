#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$(echo $5 | tr 'a-z' 'A-Z')

[ "$NOTIFY_ENABLE" != 1 ] && exit 0

msg="${NAT_NAME}
New ${protocol} port mapping: ${inner_port} -> ${outter_ip}:${outter_port}
IP4P: ${ip4p}"
[ -n "$MSG_OVERRIDE" ] && msg="$MSG_OVERRIDE"

plugin_file="/usr/lib/natmap/plugin-notify/$NOTIFY_CHANNEL.sh"
if [ -f "$plugin_file" ]; then
    source "$plugin_file" "$msg"
fi
