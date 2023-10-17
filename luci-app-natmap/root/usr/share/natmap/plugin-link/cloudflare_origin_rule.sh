#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2

get_current_rule() {
  # Function to get the current rule
  #
  # Returns:
  #   string: The current rule
  curl --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_origin/entrypoint \
    --header "X-Auth-Key: $LINK_CLOUDFLARE_API_KEY" \
    --header "X-Auth-Email: $LINK_CLOUDFLARE_EMAIL" \
    --header 'Content-Type: application/json'
}

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$LINK_ADVANCED_ENABLE" == 1 ] && [ -n "$LINK_MAX_RETRIES" ] && [ -n "$LINK_SLEEP_TIME" ]; then
  # 获取最大重试次数
  max_retries=$((LINK_MAX_RETRIES == "0" ? 1 : LINK_MAX_RETRIES))
  # 获取休眠时间
  sleep_time=$((LINK_SLEEP_TIME == "0" ? 3 : LINK_SLEEP_TIME))
fi

# 初始化参数
currrent_rule=""
retry_count=0
LINK_CLOUDFLARE_RULESET_ID=""

while true; do
  currrent_rule=$(get_current_rule)
  LINK_CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

  if [ -z "$LINK_CLOUDFLARE_RULESET_ID" ]; then
    # echo "$GENERAL_NAT_NAME - $LINK_MODE 登录失败,正在重试..."
    # Increment the retry count
    retry_count=$((retry_count + 1))

    # Check if maximum retries reached
    if [ $retry_count -eq $max_retries ]; then
      echo "$GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法登录"
      exit 1
    fi
    # echo "$GENERAL_NAT_NAME - $LINK_MODE 登录失败,休眠$sleep_time秒"
    sleep $sleep_time
  else
    echo "$GENERAL_NAT_NAME - $LINK_MODE 登录成功"
    break
  fi
done

LINK_CLOUDFLARE_RULE_NAME="\"$LINK_CLOUDFLARE_RULE_NAME\""
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$LINK_CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.origin.port = '"$outter_port"'')

# delete last_updated
body=$(echo "$new_rule" | jq '.result | del(.last_updated)')
curl --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/$LINK_CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $LINK_CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $LINK_CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"
