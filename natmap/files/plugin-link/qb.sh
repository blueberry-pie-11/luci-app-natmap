#!/bin/sh

# NATMap
protocol=$5
inner_port=$4
outter_ip=$1
outter_port=$2
ip4p=$3

rule_name=$(echo "${NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
LINK_QB_WEB_URL=$(echo $LINK_QB_WEB_URL | sed 's/\/$//')

# 获取qbcookie，直至重试次数用尽
# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 初始化参数
qbcookie=""
retry_count=0

# 判断是否开启qbittorrent的高级功能
if [ "$LINK_QB_ADVANCED_ENABLE" == 1 ]; then
    # 获取qbittorrent的最大重试次数
    case "$LINK_QB_MAX_RETRIES" in
    "")
        max_retries=1
        ;;
    "0")
        max_retries=1
        ;;
    *)
        max_retries=$LINK_QB_MAX_RETRIES
        ;;
    esac

    # 获取qbittorrent的休眠时间
    case "$LINK_QB_SLEEP_TIME" in
    "")
        sleep_time=3
        ;;
    "0")
        sleep_time=3
        ;;
    *)
        sleep_time=$LINK_QB_SLEEP_TIME
        ;;
    esac
else
    max_retries=1
    sleep_time=3
fi

while true; do
    # 获取qbcookie
    qbcookie=$(
        curl -Ssi -X POST \
            -d "username=${LINK_QB_USERNAME}&password=${LINK_QB_PASSWORD}" \
            "$LINK_QB_WEB_URL/api/v2/auth/login" |
            sed -n 's/.*\(SID=.\{32\}\);.*/\1/p'
    )

    # echo "qbcookie: $qbcookie"

    if [ -z "$qbcookie" ]; then

        echo "$NAT_NAME 登录失败,正在重试..."
        # Increment the retry count
        retry_count=$((retry_count + 1))

        # Check if maximum retries reached
        if [ $retry_count -eq $max_retries ]; then
            echo "$NAT_NAME 达到最大重试次数，无法登录"
            exit 1
        fi
        echo "$NAT_NAME 登录失败,休眠$sleep_time秒"
        sleep $sleep_time
    else
        echo "$NAT_NAME 登录成功"
        break
    fi
done

# 修改端口
curl -s -X POST \
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
