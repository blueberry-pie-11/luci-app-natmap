#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2

get_current_rule() {
  curl --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint \
    --header "X-Auth-Key: $LINK_CLOUDFLARE_API_KEY" \
    --header "X-Auth-Email: $LINK_CLOUDFLARE_EMAIL" \
    --header 'Content-Type: application/json'
}

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$LINK_ADVANCED_ENABLE" == 1 ]; then
  # 获取最大重试次数
  case "$(echo $LINK_MAX_RETRIES | sed 's/\/$//')" in
  "")
    max_retries=1
    ;;
  "0")
    max_retries=1
    ;;
  *)
    max_retries=$(echo $LINK_MAX_RETRIES | sed 's/\/$//')
    ;;
  esac

  # 获取休眠时间
  case "$(echo $LINK_SLEEP_TIME | sed 's/\/$//')" in
  "")
    sleep_time=3
    ;;
  "0")
    sleep_time=3
    ;;
  *)
    sleep_time=$(echo $LINK_SLEEP_TIME | sed 's/\/$//')
    ;;
  esac
else
  max_retries=1
  sleep_time=3
fi

# 初始化参数
currrent_rule=""
retry_count=0
LINK_CLOUDFLARE_RULESET_ID=""

while true; do
  currrent_rule=$(get_current_rule)
  LINK_CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

  if [ -z "$LINK_CLOUDFLARE_RULESET_ID" ]; then
    # echo "$LINK_MODE 登录失败,正在重试..."
    # Increment the retry count
    retry_count=$((retry_count + 1))

    # Check if maximum retries reached
    if [ $retry_count -eq $max_retries ]; then
      echo "$LINK_MODE 达到最大重试次数，无法登录"
      exit 1
    fi
    # echo "$LINK_MODE 登录失败,休眠$sleep_time秒"
    sleep $sleep_time
  else
    echo "$LINK_MODE 登录成功"
    break
  fi
done

LINK_CLOUDFLARE_RULE_NAME="\"$LINK_CLOUDFLARE_RULE_NAME\""
# replace NEW_PORT with outter_port
LINK_CLOUDFLARE_RULE_TARGET_URL=$(echo $LINK_CLOUDFLARE_RULE_TARGET_URL | sed 's/NEW_PORT/'"$outter_port"'/g')
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$LINK_CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.from_value.target_url.value = "'"$LINK_CLOUDFLARE_RULE_TARGET_URL"'"')

body=$(echo "$new_rule" | jq '.result')
# delete last_updated
body=$(echo "$body" | jq 'del(.last_updated)')
curl --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/$LINK_CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $LINK_CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $LINK_CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"
