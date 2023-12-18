#!/bin/bash
# ikuai_version=3.7.6

# natmap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

## ikuai参数获取
# lan_port
mapping_lan_port=""
if [ -z "${FORWARD_TARGET_PORT}" ] || [ "${FORWARD_TARGET_PORT}" -eq 0 ]; then
  mapping_lan_port=$outter_port
else
  mapping_lan_port=${FORWARD_TARGET_PORT}
fi

# login api and call api
ikuai_login_api="/Action/login"
ikuai_call_api="/Action/call"
call_url="$(echo $FORWARD_IKUAI_WEB_URL | sed 's/\/$//')${ikuai_call_api}"
login_url="$(echo $FORWARD_IKUAI_WEB_URL | sed 's/\/$//')${ikuai_login_api}"

# 浏览器headers
headers='{"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Content-type": "application/json;charset=utf-8",
    "Accept-Language": "zh-CN"}'

# 初始化参数
cookie=""
delete_response=""
add_response=""
comment="natmap-${GENERAL_NAT_NAME}"

# 登录
login_action() {
  # 计算密码的 MD5 哈希值并转为十六进制
  passwd=$(echo -n "$FORWARD_IKUAI_PASSWORD" | openssl dgst -md5 -hex | awk '{print $2}')
  # 拼接 salt_11 和密码，并使用 base64 进行编码
  pass=$(echo -n "salt_11$passwd" | openssl enc -base64)

  # Create the JSON payload for the login request
  login_params='{
    "username": "'"$FORWARD_IKUAI_USERNAME"'",
    "passwd": "'"$passwd"'",
    "pass": "'"$pass"'",
    "remember_password": ""
    }'

  # Send the login request and store the response headers
  login_response=$(curl -s -D - -H "$headers" -X POST -d "$login_params" "$login_url")

  # Extract the session ID (cookie) from the response headers
  cookie=$(echo "$login_response" | awk -F' ' '/Set-Cookie:/ {print $2}')

}

# 删除端口映射
delete_mapping_action() {
  # 通过$comment查询端口映射，创建show_payload字典
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
  # 获取$dnat_id
  dnat_id=$(echo "$show_response" | jq -r '.Data.data[].id' | awk '{print $0}')

  # 判断$dnat_id是否为空
  if [ -z "$dnat_id" ]; then
    echo "$GENERAL_NAT_NAME - $FORWARD_MODE 查询无端口映射"
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

    # 删除对应端口映射
    delete_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$delete_payload" "$call_url")
  fi
}

# 添加端口映射
add_mapping_action() {
  # Create the JSON payload for the port mapping modification request
  enabled="yes"
  add_payload='{
  "func_name": "dnat",
  "action": "add",
  "param": {
    "enabled": "'"$enabled"'",
    "comment": "'"$comment"'",
    "interface": "'"$FORWARD_IKUAI_MAPPING_WAN_INTERFACE"'",
    "lan_addr": "'"$FORWARD_TARGET_IP"'",
    "protocol": "'"$FORWARD_IKUAI_MAPPING_PROTOCOL"'",
    "wan_port": "'"$GENERAL_BIND_PORT"'",
    "lan_port": "'"$mapping_lan_port"'",
    "src_addr": ""
    }
    }'
  # Send the port mapping modification request and store the response
  add_response=$(curl -s -X POST -H "$headers" -b "$cookie" -d "$add_payload" "$call_url")
}

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3
retry_count=0

# 判断是否开启高级功能
if [ "${FORWARD_ADVANCED_ENABLE}" == 1 ] && [ -n "$FORWARD_ADVANCED_MAX_RETRIES" ] && [ -n "$FORWARD_ADVANCED_SLEEP_TIME" ]; then
  # 获取最大重试次数
  max_retries=$((FORWARD_ADVANCED_MAX_RETRIES == "0" ? 1 : FORWARD_ADVANCED_MAX_RETRIES))
  # 获取休眠时间
  sleep_time=$((FORWARD_ADVANCED_SLEEP_TIME == "0" ? 3 : FORWARD_ADVANCED_SLEEP_TIME))
fi

for ((retry_count = 0; retry_count <= max_retries; retry_count++)); do
  # 登录
  login_action
  if [ -n "$cookie" ]; then
    echo "$GENERAL_NAT_NAME - $FORWARD_MODE 登录成功"
    # 删除端口映射
    delete_mapping_action
    if [ "$(echo "$delete_response" | jq -r '.ErrMsg')" = "Success" ]; then
      # echo "$GENERAL_NAT_NAME - $FORWARD_MODE Port mapping deleted successfully"
      # 添加端口映射
      add_mapping_action
      # Check if the modification was successful
      if [ "$(echo "$add_response" | jq -r '.ErrMsg')" = "Success" ]; then
        echo "$GENERAL_NAT_NAME - $FORWARD_MODE Port mapping modified successfully"
        break
      else
        echo "$GENERAL_NAT_NAME - $FORWARD_MODE Failed to modify the port mapping"
      fi
    else
      echo "$GENERAL_NAT_NAME - $FORWARD_MODE Failed to delete the port mapping"
    fi
  fi
  # echo "$FORWARD_MODE 修改失败,休眠$sleep_time秒"
  sleep $sleep_time
done

# Check if maximum retries reached
if [ $retry_count -eq $max_retries ]; then
  echo "$GENERAL_NAT_NAME - $FORWARD_MODE 达到最大重试次数，无法修改"
  exit 1
fi
