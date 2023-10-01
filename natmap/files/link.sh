#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

INTERNAL_DEFINE_SCRIPT=""
case $LINK_MODE in
"qbittorrent")
    INTERNAL_DEFINE_SCRIPT="/usr/lib/natmap/plugin-link/qb.sh"
    ;;
"transmission")
    INTERNAL_DEFINE_SCRIPT="/usr/lib/natmap/plugin-link/tr.sh"
    ;;
"emby")
    INTERNAL_DEFINE_SCRIPT="/usr/lib/natmap/plugin-link/emby.sh"
    ;;
"cloudflare_origin_rule")
    INTERNAL_DEFINE_SCRIPT="/usr/lib/natmap/plugin-link/cloudflare_origin_rule.sh"
    ;;
"cloudflare_redirect_rule")
    INTERNAL_DEFINE_SCRIPT="/usr/lib/natmap/plugin-link/cloudflare_redirect_rule.sh"
    ;;
*)
    INTERNAL_DEFINE_SCRIPT=""
    ;;
esac

if [ ! -z "$INTERNAL_DEFINE_SCRIPT" ]; then
    echo "$NAT_NAME Execute internal define script: $INTERNAL_DEFINE_SCRIPT"
    source $INTERNAL_DEFINE_SCRIPT "$@"
fi
