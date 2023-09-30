#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

declare -A SCRIPTS=(
    ['qbittorrent']='/usr/lib/natmap/plugin/qb.sh'
    ['transmission']='/usr/lib/natmap/plugin/tr.sh'
    ['emby']='/usr/lib/natmap/plugin/emby.sh'
    ['cloudflare_origin_rule']='/usr/lib/natmap/plugin/cloudflare_origin_rule.sh'
    ['cloudflare_redirect_rule']='/usr/lib/natmap/plugin/cloudflare_redirect_rule.sh'
)

INTERNAL_DEFINE_SCRIPT=${SCRIPTS[$link_mode]}

if [ -n "$INTERNAL_DEFINE_SCRIPT" ]; then
    echo "$NAT_NAME Execute internal define script: $INTERNAL_DEFINE_SCRIPT"
    "$INTERNAL_DEFINE_SCRIPT" "$@"
fi
