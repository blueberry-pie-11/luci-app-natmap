#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

if [ ! -n "$FORWARD_MODE" ]; then
    exit 0
fi

internal_define_script=""
case $LINK_MODE in
"qbittorrent")
    internal_define_script="/usr/share/natmap/plugin-link/qb.sh"
    ;;
"transmission")
    internal_define_script="/usr/share/natmap/plugin-link/tr.sh"
    ;;
"emby")
    internal_define_script="/usr/share/natmap/plugin-link/emby.sh"
    ;;
"cloudflare_origin_rule")
    internal_define_script="/usr/share/natmap/plugin-link/cloudflare_origin_rule.sh"
    ;;
"cloudflare_redirect_rule")
    internal_define_script="/usr/share/natmap/plugin-link/cloudflare_redirect_rule.sh"
    ;;
*)
    internal_define_script=""
    ;;
esac

if [ ! -z "$internal_define_script" ]; then
    echo "$NAT_NAME Execute internal define script: $internal_define_script"
    source "$internal_define_script" "$@"
fi
