#!/bin/sh

# NATMap

# LINK_TR_RPC_URL="http://192.168.100.170:9091/transmission/rpc"
LINK_TR_RPC_URL="http://tr.lan:9091"
url="$LINK_TR_RPC_URL/transmission/rpc"
LINK_TR_USERNAME="admin"
LINK_TR_PASSWORD="123"
# update port
trauth="-u $LINK_TR_USERNAME:$LINK_TR_PASSWORD"
trsid=""

echo "url: $url"
echo "username: $LINK_TR_USERNAME"
echo "password: $LINK_TR_PASSWORD"
echo "trauth: $trauth"

# # 获取trsid，直至重试次数用尽
max_retries=2
retry_count=0
sleep_time=1

while true; do
    trsid=$(curl -s $trauth $url | sed 's/.*<code>//g;s/<\/code>.*//g')

    echo "trsid: $trsid"
    #!bin/sh
    if (echo $trsid | grep -q "X-Transmission-Session-Id"); then
        echo "transmission登录成功"
        break
    else
        echo "transmission登录失败,正在重试..."

        # Increment the retry count
        # echo "retry_count: $retry_count"
        retry_count=$((retry_count + 1))

        # Check if maximum retries reached
        if [ $retry_count -eq $max_retries ]; then
            echo "达到最大重试次数，无法登录"
            break
        fi
        echo "transmission登录失败,休眠$sleep_time秒"
        sleep $sleep_time
    fi
done

# # 修改端口
# while true; do
#     tr_result=$(curl -s -X POST \
#         -H "${trsid}" $trauth \
#         -d '{"method":"session-set","arguments":{"peer-port":'5865'}}' \
#         "$url")

#     echo "tr_result: $tr_result"

#     if [ "$(echo "$tr_result" | jq -r '.result')" = "success" ]; then
#         echo "transmission port modified successfully"
#         break
#     else
#         echo "transmission Failed to modify the port"
#         sleep 3
#     fi
# done
