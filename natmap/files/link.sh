#!/bin/sh

INTERNAL_DEFINE_SCRIPT = ""
case ${link_mode} in
'qbittorrent')
    INTERNAL_DEFINE_SCRIPT=/usr/lib/natmap/plugin/qb.sh
    ;;
'transmission')
    INTERNAL_DEFINE_SCRIPT=/usr/lib/natmap/plugin/tr.sh
    ;;
'emby')
    INTERNAL_DEFINE_SCRIPT=/usr/lib/natmap/plugin/emby.sh
    ;;
'cloudflare_origin_rule')
    INTERNAL_DEFINE_SCRIPT=/usr/lib/natmap/plugin/cloudflare_origin_rule.sh
    ;;
'cloudflare_redirect_rule')
    INTERNAL_DEFINE_SCRIPT=/usr/lib/natmap/plugin/cloudflare_redirect_rule.sh
    ;;
esac

if [ ! -z $INTERNAL_DEFINE_SCRIPT ]; then
    echo "$NAT_NAME Excute internal define script: $INTERNAL_DEFINE_SCRIPT"
    $INTERNAL_DEFINE_SCRIPT "$@"
fi
