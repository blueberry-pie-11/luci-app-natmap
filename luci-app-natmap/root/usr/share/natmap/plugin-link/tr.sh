#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

LINK_TR_RPC_URL=$(echo $LINK_TR_RPC_URL | sed 's/\/$//')
url="$LINK_TR_RPC_URL/transmission/rpc"
# update port
trauth="-u $LINK_TR_USERNAME:$LINK_TR_PASSWORD"

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "${LINK_ADVANCED_ENABLE}" == 1 ] && [ -n "$LINK_MAX_RETRIES" ] && [ -n "$LINK_SLEEP_TIME" ]; then
    # 获取最大重试次数
    max_retries=$((LINK_MAX_RETRIES == "0" ? 1 : LINK_MAX_RETRIES))
    # 获取休眠时间
    sleep_time=$((LINK_SLEEP_TIME == "0" ? 3 : LINK_SLEEP_TIME))
fi

# 初始化参数
# # 获取trsid，直至重试次数用尽
trsid=""
retry_count=0

while true; do
    trsid=$(curl -s $trauth $url | sed 's/.*<code>//g;s/<\/code>.*//g')

    # echo "trsid: $trsid"

    if (echo $trsid | grep -q "X-Transmission-Session-Id"); then
        echo "$GENERAL_NAT_NAME - $LINK_MODE 登录成功"
        break
    else
        # echo "$LINK_MODE 登录失败,正在重试..."
        # Increment the retry count
        retry_count=$((retry_count + 1))

        # Check if maximum retries reached
        if [ $retry_count -eq $max_retries ]; then
            echo "$GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法登录"
            exit 1
        fi
        # echo "$LINK_MODE 登录失败,休眠$sleep_time秒"
        sleep $sleep_time
    fi
done

# 修改端口
while true; do
    tr_result=$(curl -s -X POST \
        -H "${trsid}" $trauth \
        -d '{"method":"session-set","arguments":{"peer-port":'${outter_port}'}}' \
        "$url")

    if [ "$(echo "$tr_result" | jq -r '.result')" = "success" ]; then
        echo "transmission port modified successfully"
        break
    else
        echo "transmission Failed to modify the port"
        sleep 3
    fi
done

if [ "${LINK_TR_ALLOW_IPV6}" == 1 ]; then
    rule_name=$(echo "${GENERAL_NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
    # ipv6 allow
    uci set firewall.$rule_name=rule
    uci set firewall.$rule_name.name='Allow-Transmission-IPv6'
    uci set firewall.$rule_name.src='wan'
    uci set firewall.$rule_name.dest='lan'
    uci set firewall.$rule_name.target='ACCEPT'
    uci set firewall.$rule_name.proto='tcp udp'
    if uci get firewall.$rule_name.dest_ip >/dev/null 2>&1; then
        uci del firewall.$rule_name.dest_ip
    fi

    for ip in $LINK_TR_IPV6_ADDRESS; do
        uci add_list firewall.$rule_name.dest_ip="${ip}"
    done
    uci set firewall.$rule_name.family='ipv6'
    uci set firewall.$rule_name.dest_port="${outter_port}"
    # reload
    uci commit firewall
    /etc/init.d/firewall reload
fi
