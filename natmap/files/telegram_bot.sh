#!/bin/sh

text="$1"
id=$2
chat_id=$3
token=$4
function curl_proxy() {
    if [ -z "$PROXY" ]; then
        curl "$@"
    else
        curl -x $PROXY "$@"
    fi
}

max_attempts=5
sleep_duration=3

for ((attempt=1; attempt<=max_attempts; attempt++)); do
    response=$(curl_proxy -4 -Ss -o /dev/null -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${IM_NOTIFY_CHANNEL_TELEGRAM_BOT_CHAT_ID}"'", "text": "'"${text}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${IM_NOTIFY_CHANNEL_TELEGRAM_BOT_TOKEN}/sendMessage")
    
    status=$?
    if [ $status -eq 0 ]; then
        break
    fi
    
    sleep_duration=$((sleep_duration * attempt))
    sleep $sleep_duration
done