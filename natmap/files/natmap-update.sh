#!/bin/sh

. /usr/share/libubox/jshn.sh

(
	json_init
	json_add_string ip "$1"
	json_add_int port "$2"
	json_add_int inner_port "$4"
	json_add_string protocol "$5"
	json_add_string name "$NAT_NAME"
	json_dump >/var/run/natmap/$PPID.json
)

[ -n "${NOTIFY_SCRIPT}" ] && {
	export -n NOTIFY_SCRIPT
	source "${NOTIFY_SCRIPT}" "$@"
}

# link setting
source /usr/lib/natmap/link.sh "$@"

# forward setting
source /usr/lib/natmap/forward.sh "$@"

# notify setting
source /usr/lib/natmap/notify.sh "$@"
