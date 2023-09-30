#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2

get_current_rule() {
  curl --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_origin/entrypoint \
    --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    --header 'Content-Type: application/json'
}

currrent_rule=$(get_current_rule)

CLOUDFLARE_RULE_NAME="\"$CLOUDFLARE_RULE_NAME\""
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.origin.port = '"$outter_port"'')

CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

body=$(echo "$new_rule" | jq '.result')
# delete last_updated
body=$(echo "$body" | jq 'del(.last_updated)')
curl --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/$CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"
