#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

rule_name=$(echo "${NAT_NAME}_v4" | awk '{gsub(/[^a-zA-Z0-9]/,"_"); print tolower($0)}')
final_forward_port=${FORWARD_PORT:-$outter_port}

# ipv4 redirect
uci set firewall.$rule_name="redirect"
uci set firewall.$rule_name.name="$NAT_NAME"
uci set firewall.$rule_name.proto=$protocol
uci set firewall.$rule_name.src=$WAN_INTERFACE
uci set firewall.$rule_name.dest=$TARGET_INTERFACE
uci set firewall.$rule_name.target='DNAT'
uci set firewall.$rule_name.src_dport="${inner_port}"
uci set firewall.$rule_name.dest_ip="${FORWARD_TARGET}"
uci set firewall.$rule_name.dest_port="${final_forward_port}"

# reload
uci commit firewall
/etc/init.d/firewall reload
