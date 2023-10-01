#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2

# Reuse curl connection with keepalive
curl_options="--keepalive 30"

get_current_rule() {
  curl $curl_options --request GET \
    --url "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint" \
    --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    --header "Content-Type: application/json"
}

currrent_rule=$(get_current_rule)

CLOUDFLARE_RULE_NAME="\"$CLOUDFLARE_RULE_NAME\""
# replace NEW_PORT with outer_port
CLOUDFLARE_RULE_TARGET_URL=${CLOUDFLARE_RULE_TARGET_URL/NEW_PORT/$outer_port}

# Perform data manipulation using a programming language instead of external commands
new_rule=$(echo "$currrent_rule" | jq --arg CLOUDFLARE_RULE_NAME "$CLOUDFLARE_RULE_NAME" --arg CLOUDFLARE_RULE_TARGET_URL "$CLOUDFLARE_RULE_TARGET_URL" '.result.rules | to_entries | map(select(.value.description == $CLOUDFLARE_RULE_NAME)) | .[].key | . as $key | .[$key].action_parameters.from_value.target_url.value = $CLOUDFLARE_RULE_TARGET_URL')

CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

body=$(echo "$new_rule" | jq '.result')
# delete last_updated
body=$(echo "$body" | jq 'del(.last_updated)')

# Batch API calls into a single request
data="{\"rules\": $body}"

curl $curl_options --request PUT \
  --url "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/$CLOUDFLARE_RULESET_ID" \
  --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  --header "Content-Type: application/json" \
  --data "$data"

