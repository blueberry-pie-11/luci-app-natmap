#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2
LINK_EMBY_URL=$(echo $LINK_EMBY_URL | sed 's/\/$//')

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$LINK_ADVANCED_ENABLE" == 1 ] && [ -n "$LINK_MAX_RETRIES" ] && [ -n "$LINK_SLEEP_TIME" ]; then
    # 获取最大重试次数
    max_retries=$((LINK_MAX_RETRIES == "0" ? 1 : LINK_MAX_RETRIES))
    # 获取休眠时间
    sleep_time=$((LINK_SLEEP_TIME == "0" ? 3 : LINK_SLEEP_TIME))
fi

# 初始化参数
current_cfg=""
retry_count=0

while true; do
    current_cfg=$(curl -v $LINK_EMBY_URL/emby/System/Configuration?api_key=$LINK_EMBY_API_KEY)

    if [ -z "$current_cfg" ]; then

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
    else
        echo "$GENERAL_NAT_NAME - $LINK_MODE 登录成功"
        break
    fi
done

new_cfg=$current_cfg
if [ ! -z $LINK_EMBY_USE_HTTPS ] && [ $LINK_EMBY_USE_HTTPS = '1' ]; then
    new_cfg=$(echo $current_cfg | jq ".PublicHttpsPort = $outter_port")
else
    new_cfg=$(echo $current_cfg | jq ".PublicPort = $outter_port")
fi

if [ ! -z $LINK_EMBY_UPDATE_HOST_WITH_IP ] && [ $LINK_EMBY_UPDATE_HOST_WITH_IP = '1' ]; then
    new_cfg=$(echo $new_cfg | jq ".WanDdns = \"$outter_ip\"")
fi

curl -X POST "$LINK_EMBY_URL/emby/System/Configuration?api_key=$LINK_EMBY_API_KEY" -H "accept: */*" -H "Content-Type: application/json" -d "$new_cfg"
