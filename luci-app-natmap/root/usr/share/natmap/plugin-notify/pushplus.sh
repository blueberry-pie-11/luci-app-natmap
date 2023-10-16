#!/bin/sh

text="$1"
token=$2

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$NOTIFY_ADVANCED_ENABLE" == 1 ]; then
    # 获取最大重试次数
    case "$(echo $NOTIFY_MAX_RETRIES | sed 's/\/$//')" in
    "")
        max_retries=1
        ;;
    "0")
        max_retries=1
        ;;
    *)
        max_retries=$(echo $NOTIFY_MAX_RETRIES | sed 's/\/$//')
        ;;
    esac

    # 获取休眠时间
    case "$(echo $NOTIFY_SLEEP_TIME | sed 's/\/$//')" in
    "")
        sleep_time=3
        ;;
    "0")
        sleep_time=3
        ;;
    *)
        sleep_time=$(echo $NOTIFY_SLEEP_TIME | sed 's/\/$//')
        ;;
    esac
else
    max_retries=1
    sleep_time=3
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
            exit 1
        fi
        # echo "$NOTIFY_MODE 登录失败,休眠$sleep_time秒"
        sleep $sleep_time
    fi
done
