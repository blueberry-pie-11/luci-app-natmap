#!/bin/bash

title="natmap - PT 更新"
desp="SSSSSSSSSSSSS"
sendkey="SCT23607T3tefTJKJl5IsmQKZeoKxlxYt"
url="https://sctapi.ftqq.com/$sendkey.send"
postdata="title=$title&desp=$desp"
message=(
    "--header" "Content-type: application/x-www-form-urlencoded"
    "--data" "$postdata"
)

result=$(curl -X POST -s -o /dev/null -w "%{http_code}" "$url" "${message[@]}")
if [ $result -eq 200 ]; then
    echo "$GENERAL_NAT_NAME - $NOTIFY_MODE 发送成功"
else
    echo "$NOTIFY_MODE 登录失败,休眠$sleep_time秒"
fi
