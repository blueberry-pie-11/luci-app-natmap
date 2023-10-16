#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

if [ "$FORWARD_MODE" != local ]; then
	exit 0
fi

if [ ! -z "$FORWARD_NATMAP_USE_NATMAP" ] && [ "$FORWARD_NATMAP_USE_NATMAP" = 1 ]; then
	exit 0
fi

if [ -z "$FORWARD_TARGET_PORT" ]; then
	exit 0
fi

if [ -z "$FORWARD_TARGET_IP" ]; then
	exit 0
fi

rule_name=$(echo "${GENERAL_NAT_NAME}_v4" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')

# printf $rule_name
echo "rule_name: $rule_name"

final_forward_target_port=$FORWARD_TARGET_PORT
if [ $final_forward_target_port = 0 ]; then
	final_forward_target_port=$outter_port
fi
# ipv4 redirect
uci set firewall.$rule_name=redirect
uci set firewall.$rule_name.name="$GENERAL_NAT_NAME"
uci set firewall.$rule_name.proto=$protocol
uci set firewall.$rule_name.src=$GENERAL_WAN_INTERFACE
uci set firewall.$rule_name.dest=$FORWOARD_TARGET_INTERFACE
uci set firewall.$rule_name.target='DNAT'
uci set firewall.$rule_name.src_dport="${inner_port}"
uci set firewall.$rule_name.dest_ip="${FORWARD_TARGET_IP}"
uci set firewall.$rule_name.dest_port="${final_forward_target_port}"

# reload
uci commit firewall
/etc/init.d/firewall reload