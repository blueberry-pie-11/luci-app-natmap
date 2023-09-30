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

if [ $TR_ALLOW_IPV6 = 1 ]; then
    rule_name=$(echo "${NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
    # ipv6 allow
    uci batch <<EOF
        set firewall.$rule_name=rule
        set firewall.$rule_name.name='Allow-Transmission-IPv6'
        set firewall.$rule_name.src='wan'
        set firewall.$rule_name.dest='lan'
        set firewall.$rule_name.target='ACCEPT'
        set firewall.$rule_name.proto='tcp udp'
        del firewall.$rule_name.dest_ip
        EOF

    for ip in $TR_IPV6_ADDRESS; do
        uci add_list firewall.$rule_name.dest_ip="${ip}"
    done

    uci set firewall.$rule_name.family='ipv6'
    uci set firewall.$rule_name.dest_port="${outter_port}"

    # reload
    uci commit firewall
    /etc/init.d/firewall reload
fi