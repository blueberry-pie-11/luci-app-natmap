#!/bin/sh

# natmap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# ikuai
# ----------------
# ikuai版本
ikuai_version=3.7.6
# ----------------
ikuai_url=$(echo $FORWARD_IKUAI_WEB_URL | sed 's/\/$//')
ikuai_user=$FORWARD_IKUAI_USERNAME
ikual_passwd=$FORWARD_IKUAI_PASSWORD
mapping_protocol=$FORWARD_IKUAI_MAPPING_PROTOCOL
mapping_wan_interface=$FORWARD_IKUAI_MAPPING_WAN_INTERFACE
mapping_wan_port=$GENERAL_BIND_PORT
mapping_lan_addr=$FORWARD_TARGET_IP

# 单独配置mapping_lan_port
mapping_lan_port=""
if [ -z "${FORWARD_TARGET_PORT}" ] || [ "${FORWARD_TARGET_PORT}" -eq 0 ]; then
  mapping_lan_port=$outter_port
else
  mapping_lan_port=${FORWARD_TARGET_PORT}
fi

# url
ikuai_login_api="/Action/login"
ikuai_call_api="/Action/call"
call_url="${ikuai_url}${ikuai_call_api}"
login_url="${ikuai_url}${ikuai_login_api}"
# 浏览器headers
headers='{"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Content-type": "application/json;charset=utf-8",
    "Accept-Language": "zh-CN"}'

# Set the login parameters
# 计算密码的 MD5 哈希值并转为十六进制
passwd=$(echo -n "$ikual_passwd" | openssl dgst -md5 -hex | awk '{print $2}')

# 拼接 salt_11 和密码，并使用 base64 进行编码
pass=$(echo -n "salt_11$passwd" | openssl enc -base64)

# Create the JSON payload for the login request
login_params='{
    "username": "'"$ikuai_user"'",
    "passwd": "'"$passwd"'",
    "pass": "'"$pass"'",
    "remember_password": ""
    }'

# echo "call_url: $call_url"
# echo "login_url: $login_url"
# echo "login_params: $login_params"
# echo "general_nat_name: $GENERAL_NAT_NAME"

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$FORWARD_ADVANCED_ENABLE" == 1 ] && [ -n "$FORWARD_MAX_RETRIES" ] && [ -n "$FORWARD_SLEEP_TIME" ]; then
  # 获取最大重试次数
  max_retries=$((FORWARD_MAX_RETRIES == "0" ? 1 : FORWARD_MAX_RETRIES))
  # 获取休眠时间
  sleep_time=$((FORWARD_SLEEP_TIME == "0" ? 3 : FORWARD_SLEEP_TIME))
fi

# 初始化参数
cookie=""
retry_count=0

# 登录
while true; do
  # Send the login request and store the response headers
  login_response=$(curl -s -D - -H "$headers" -X POST -d "$login_params" "$login_url")

  # Print the login response
  # echo "login_response: $(echo "$login_response" | sed 's/,/,\\n/g')"

  # Extract the session ID (cookie) from the response headers
  cookie=$(echo "$login_response" | awk -F' ' '/Set-Cookie:/ {print $2}')

  # Print the session ID
  if [ -z "$cookie" ]; then
    # echo "$FORWARD_MODE 登录失败,正在重试..."
    # Increment the retry count
    retry_count=$((retry_count + 1))

    # Check if maximum retries reached
    if [ $retry_count -eq $max_retries ]; then
      echo "$FORWARD_MODE 达到最大重试次数，无法登录"
      break
    fi
    # echo "$FORWARD_MODE 登录失败,休眠$sleep_time秒"
    sleep $sleep_time
  else
    echo "$FORWARD_MODE 登录成功"
    break
  fi
done

# Set the parameters for the port mapping modification
enabled="yes"
comment="natmap-${GENERAL_NAT_NAME}"

# 通过$comment查询端口映射
# 创建show_payload字典
show_payload='{
  "func_name": "dnat",
  "action": "show",
  "param": {
    "FINDS": "lan_addr,lan_port,wan_port,comment",
    "KEYWORDS": "'"$comment"'",
    "TYPE": "total,data",
    "limit": "0,20",
    "ORDER_BY": "",
    "ORDER": ""
  }
}'

show_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$show_payload" "$call_url")

# echo "show_response: $(echo "$show_response" | sed 's/,/,\\n/g')"

# 获取$dnat_id
dnat_id=$(echo "$show_response" | jq -r '.Data.data[].id' | awk '{print $0}')

# 判断$dnat_id是否为空
if [ -z "$dnat_id" ]; then
  echo "ikuai查询无 $comment 端口映射"
else
  # echo "ikuai 端口映射 dnat_id: $dnat_id"

  # 创建delete_payload字典
  delete_payload='{
    "func_name": "dnat",
    "action": "del",
    "param": {
      "id": "'"$dnat_id"'"
    }
  }'
  # 打印delete_payload字典
  # echo "delete_payload: $delete_payload"

  # 删除对应端口映射
  delete_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$delete_payload" "$call_url")

  # 打印delete_response
  # echo "delete_response: $(echo "$delete_response" | sed 's/,/,\\n/g')"

  if [ "$(echo "$delete_response" | jq -r '.ErrMsg')" = "Success" ]; then
    echo "ikuai $comment Port mapping deleted successfully"
  else
    echo "Failed to delete the port mapping $comment"
    # echo "Delete_response: $delete_response"
    break
  fi

fi

# Create the JSON payload for the port mapping modification request
add_payload='{
  "func_name": "dnat",
  "action": "add",
  "param": {
    "enabled": "'"$enabled"'",
    "comment": "'"$comment"'",
    "interface": "'"$mapping_wan_interface"'",
    "lan_addr": "'"$mapping_lan_addr"'",
    "protocol": "'"$mapping_protocol"'",
    "wan_port": "'"$mapping_wan_port"'",
    "lan_port": "'"$mapping_lan_port"'",
    "src_addr": ""
    }
}'

# 打印add_payload字典
# echo "add_payload: $add_payload"

# Send the port mapping modification request and store the response
add_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$add_payload" "$call_url")

# Print the port mapping modification response
# echo "add_response: $(echo "$add_response" | sed 's/,/,\\n/g')"

# Check if the modification was successful
if [ "$(echo "$add_response" | jq -r '.ErrMsg')" = "Success" ]; then
  echo "ikuai $comment Port mapping modified successfully"
else
  echo "ikuai Failed to modify the port mapping $comment"
  # echo "Response: $response"
  break
fi
