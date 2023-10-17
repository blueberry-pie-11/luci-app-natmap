#!/bin/bash

text="$1"
token=$2

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$NOTIFY_ADVANCED_ENABLE" == 1 ] && [ -n "$NOTIFY_MAX_RETRIES" ] && [ -n "$NOTIFY_SLEEP_TIME" ]; then
    # 获取最大重试次数
    max_retries=$((NOTIFY_MAX_RETRIES == "0" ? 1 : NOTIFY_MAX_RETRIES))
    # 获取休眠时间
    sleep_time=$((NOTIFY_SLEEP_TIME == "0" ? 3 : NOTIFY_SLEEP_TIME))
fi

while true; do
    curl -4 -Ss -X POST \
        -H 'Content-Type: application/json' \
        -d '{"token": "'"${NOTIFY_PUSHPLUS_TOKEN}"'", "content": "'"${text}"'", "title": "NATMap"}' \
        "http://www.pushplus.plus/send"
    status=$?
    if [ $status -eq 0 ]; then
        echo "$NOTIFY_MODE 发送成功"
        break
    else
        # echo "$NOTIFY_MODE 发送失败，正在重试..."

        # Increment the retry count
        retry_count=$((retry_count + 1))
        # Check if maximum retries reached
        if [ $retry_count -eq $max_retries ]; then
            echo "$NOTIFY_MODE 达到最大重试次数，无法登录"
            break
        fi
        # echo "$NOTIFY_MODE 登录失败,休眠$sleep_time秒"
        sleep $sleep_time
    fi
done
