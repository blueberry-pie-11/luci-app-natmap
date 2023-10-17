#!/bin/bash
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

link_script=""
case $LINK_MODE in
"qbittorrent")
    link_script="/usr/share/natmap/plugin-link/qb.sh"
    ;;
"transmission")
    link_script="/usr/share/natmap/plugin-link/tr.sh"
    ;;
"emby")
    link_script="/usr/share/natmap/plugin-link/emby.sh"
    ;;
"cloudflare_origin_rule")
    link_script="/usr/share/natmap/plugin-link/cloudflare_origin_rule.sh"
    ;;
"cloudflare_redirect_rule")
    link_script="/usr/share/natmap/plugin-link/cloudflare_redirect_rule.sh"
    ;;
*)
    link_script=""
    ;;
esac

if [ -n "${link_script}" ]; then
    echo "$GENERAL_NAT_NAME Execute link script: $link_script"
    source "${link_script}" "$@"
fi
