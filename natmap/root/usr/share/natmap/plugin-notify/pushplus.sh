#!/bin/sh

text="$1"
token=$2

while true; do
    curl -4 -Ss -X POST \
        -H 'Content-Type: application/json' \
        -d '{"token": "'"${NOTIFY_PUSHPLUS_TOKEN}"'", "content": "'"${text}"'", "title": "NATMap"}' \
        "http://www.pushplus.plus/send"
    status=$?
    if [ $status -eq 0 ]; then
        echo "pushplus发送成功"
        break
    else
        echo "pushplus发送失败，正在重试..."
        sleep 3
    fi
done
