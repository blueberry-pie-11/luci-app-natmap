#!/bin/sh

# NATMap
protocol=$5
inner_port=$4
outter_ip=$1
outter_port=$2
ip4p=$3

rule_name=$(echo "${NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
LINK_QB_WEB_URL=$(echo $LINK_QB_WEB_URL | sed 's/\/$//')

# 初始化qbcookie
qbcookie=""
while true; do
    # update port
    qbcookie=$(
        curl -Ssi -X POST \
            -d "username=${LINK_QB_USERNAME}&password=${LINK_QB_PASSWORD}" \
            "$LINK_QB_WEB_URL/api/v2/auth/login" |
            sed -n 's/.*\(SID=.\{32\}\);.*/\1/p'
    )

    # echo "qbcookie: $qbcookie"
    # echo "outter_port: $outter_port"

    if [ $qbcookie = "" ]; then
        echo "qbittorrent登录失败,正在重试..."
        sleep 3
    else
        echo "qbittorrent登录成功"
        break
    fi
done

curl -X POST \
    -b "${qbcookie}" \
    -d 'json={"listen_port":"'${outter_port}'"}' \
    "$LINK_QB_WEB_URL/api/v2/app/setPreferences"
#
# qb_allow_ipv6
if [ $LINK_QB_ALLOW_IPV6 = 1 ]; then
    echo "rule_name: $rule_name"
    # ipv6 allow
    uci set firewall.$rule_name=rule
    uci set firewall.$rule_name.name='Allow-qBittorrent-IPv6'
    uci set firewall.$rule_name.src='wan'
    uci set firewall.$rule_name.dest='lan'
    uci set firewall.$rule_name.target='ACCEPT'
    uci set firewall.$rule_name.proto='tcp udp'
    # uci get firewall.$rule_name.dest_ip
    # check if dest_ip is already set with return code
    if uci get firewall.$rule_name.dest_ip >/dev/null 2>&1; then
        uci del firewall.$rule_name.dest_ip
    fi

    # add dest_ip list
    for ip in $LINK_QB_IPV6_ADDRESS; do
        uci add_list firewall.$rule_name.dest_ip="${ip}"
    done

    uci set firewall.$rule_name.family='ipv6'
    uci set firewall.$rule_name.dest_port="${outter_port}"

    # reload
    uci commit firewall
    /etc/init.d/firewall reload
fi
