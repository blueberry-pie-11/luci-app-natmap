#!/bin/bash

text="$1"
id=$2
chat_id=$3
token=$4
curl_proxy() {
    if [ -z "$NOTIFY_TELEGRAM_BOT_PROXY" ]; then
        curl "$@"
    else
        curl -x $NOTIFY_TELEGRAM_BOT_PROXY "$@"
    fi
}

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

# # 判断是否开启高级功能
# if [ "$NOTIFY_ADVANCED_ENABLE" == 1 ]; then
#     # 获取最大重试次数
#     max_retries="${NOTIFY_MAX_RETRIES%/:-$max_retries}"
#     # 获取休眠时间
#     sleep_time="${NOTIFY_SLEEP_TIME%/:-$sleep_time}"
# fi

while true; do
    curl_proxy -4 -Ss -o /dev/null -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${NOTIFY_TELEGRAM_BOT_CHAT_ID}"'", "text": "'"${text}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${NOTIFY_TELEGRAM_BOT_TOKEN}/sendMessage"
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
