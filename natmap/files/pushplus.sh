#!/bin/sh

text="$1"
token=$2
url="http://www.pushplus.plus/send"
headers="Content-Type: application/json"

curl -4 -Ss -X POST \
    -H "$headers" \
    -d '{"token": "'"${IM_NOTIFY_CHANNEL_PUSHPLUS_TOKEN}"'", "content": "'"${text}"'", "title": "NATMap"}' \
    -f -m 3 -w "\n\nTiming\n\nDNS Lookup: %{time_namelookup}s\nConnect: %{time_connect}s\nPre-transfer: %{time_pretransfer}s\nStart Transfer: %{time_starttransfer}s\n\n" \
    "$url"
