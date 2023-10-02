#!/bin/sh

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

while true; do

    curl_proxy -4 -Ss -o /dev/null -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${NOTIFY_TELEGRAM_BOT_CHAT_ID}"'", "text": "'"${text}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${NOTIFY_TELEGRAM_BOT_TOKEN}/sendMessage"
    status=$?
    if [ $status -eq 0 ]; then
        break
    else
        sleep 3
    fi
done
