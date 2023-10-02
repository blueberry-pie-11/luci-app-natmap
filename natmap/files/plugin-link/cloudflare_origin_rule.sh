#!/bin/sh

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

currrent_rule=$(get_current_rule)

LINK_CLOUDFLARE_RULE_NAME="\"$LINK_CLOUDFLARE_RULE_NAME\""
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$LINK_CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.origin.port = '"$outter_port"'')

LINK_CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

# delete last_updated
body=$(echo "$new_rule" | jq '.result | del(.last_updated)')
curl --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/$LINK_CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $LINK_CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $LINK_CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"
