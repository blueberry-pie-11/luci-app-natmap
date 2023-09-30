#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5
env

TR_RPC_URL=$(echo $TR_RPC_URL | sed 's/\/$//')
# update port
trauth="-u $TR_USERNAME:$TR_PASSWORD"
trsid=$(curl -s $trauth $TR_RPC_URL/transmission/rpc | sed 's/.*<code>//g;s/<\/code>.*//g')
curl -X POST \
    -H "${trsid}" $trauth \
    -d '{"method":"session-set","arguments":{"peer-port":'${outter_port}'}}' \
    "$TR_RPC_URL/transmission/rpc"

if [ "$TR_ALLOW_IPV6" = 1 ]; then
    # ipv6 allow
    uci set firewall.${NAT_NAME}_v6_allow=rule
    uci set firewall.${NAT_NAME}_v6_allow.name='Allow-Transmission-IPv6'
    uci set firewall.${NAT_NAME}_v6_allow.src='wan'
    uci set firewall.${NAT_NAME}_v6_allow.dest='lan'
    uci set firewall.${NAT_NAME}_v6_allow.target='ACCEPT'
    uci set firewall.${NAT_NAME}_v6_allow.proto='tcp udp'
    if uci get firewall.${NAT_NAME}_v6_allow.dest_ip >/dev/null 2>&1; then
        uci del firewall.${NAT_NAME}_v6_allow.dest_ip
    fi

    for ip in $TR_IPV6_ADDRESS; do
        uci add_list firewall.${NAT_NAME}_v6_allow.dest_ip="${ip}"
    done
    uci set firewall.${NAT_NAME}_v6_allow.family='ipv6'
    uci set firewall.${NAT_NAME}_v6_allow.dest_port="${outter_port}"
    # reload
    uci commit firewall
    /etc/init.d/firewall reload
fi