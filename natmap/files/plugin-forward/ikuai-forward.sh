#!/bin/sh

# natmap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# ikuai
ikuai_url=$IKUAI_WEB_UI_URL
ikuai_user=$IKUAI_USERNAME
ikual_passwd=$IKUAI_PASSWORD
mapping_protocol=$IKUAL_MAPPING_PROTOCOL
mapping_wan_interface=$IKUAL_MAPPING_WAN_INTERFACE
mapping_wan_port=$BIND_PORT
mapping_lan_addr=$FORWARD_TARGET
# 单独配置mapping_lan_port
# mapping_lan_port=""
# if [ "${FORWARD_PORT}" == 0 ] || [ "${FORWARD_PORT}" == "" ]; then
#   mapping_lan_port=$outter_port
# else
#   mapping_lan_port=${FORWARD_PORT}
# fi
mapping_lan_port="${FORWARD_PORT:-$outter_port}"

# url
ikuai_login_api="/Action/login"
ikuai_call_api="/Action/call"
call_url="${ikuai_url}/${ikuai_call_api}"
login_url="${ikuai_url}/${ikuai_login_api}"
# 浏览器headers
headers = '"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Content-type": "application/json;charset=utf-8",
    "Accept-Language": "zh-CN",'

# Set the login parameters
passwd=$(echo -n "$ikual_passwd" | md5sum | awk '{print $1}')
pass=$(echo -n "salt_11$password" | base64)

# Create the JSON payload for the login request
login_params='{
    "username": "'"$ikuai_user"'",
    "passwd": "'"$passwd"'",
    "pass": "'"$pass"'",
    "remember_password": ""
}'

# Send the login request and store the response headers
login_response=$(curl -s -D - -X POST -H "$headers" -d "$login_params" "$login_url")

# Extract the session ID (cookie) from the response headers
cookie=$(echo "$login_response" | grep -i "Set-Cookie:" | awk -F' ' '{print $2}')

# Print the session ID
echo "cookie: $cookie"

# Set the parameters for the port mapping modification
enabled="yes"
comment="natmap-${NAT_NAME}"
src_addr=""

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

# 输出show_payload
# echo "show_payload: $show_payload"

show_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$show_payload" "$call_url")
# echo "show_response: $(echo "$show_response" | sed 's/,/,\\n/g')"

# 获取$dnat_id
dnat_id=$(echo "$show_response" | jq -r '.Data.data[].id' | awk '{print $0}')

# 判断$dnat_id是否为空
if [ -z "$dnat_id" ]; then
  echo "查询无端口映射"
else
  echo "dnat_id: $dnat_id"

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
  if echo "$delete_response" | grep -q "\"ErrMsg\":\"Success\""; then
    echo "Port mapping deleted successfully"
  else
    echo "Failed to delete the port mapping"
    echo "Response: $delete_response"
    exit 1
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
    "src_addr": "'"$src_addr"'"
  }
}'

# Send the port mapping modification request and store the response
add_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$add_payload" "$call_url")

# Check if the modification was successful
if echo "$add_response" | grep -q "\"ErrMsg\":\"Success\""; then
  echo "Port mapping modified successfully"
else
  echo "Failed to modify the port mapping"
  echo "Response: $response"
  exit 1
fi
