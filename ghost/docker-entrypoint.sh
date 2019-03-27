#!/bin/bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'MM_PASSWORD' 'example'
# (will allow for "$MM_PASSWORD_FILE" to fill in the value of
#  "$MM_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "${var}"="${val}"
	unset "$fileVar"
}

# Read environment variables or set default values
DB_HOST="${DB_HOST:-db}"
DB_PORT_NUMBER="${DB_PORT_NUMBER:-3306}"
file_env 'MM_USERNAME' 'mmuser'
file_env 'MM_PASSWORD' 'mmuser_password'
file_env 'MM_DBNAME' 'mattermost'
#file_env 'MM_SQLSETTINGS_DATASOURCE' 'mmuser:mmuser_password@tcp(db:3306)/mattermost?charset=utf8mb4,utf8&readTimeout=30s&writeTimeout=30s'
MM_CONFIG="${MM_CONFIG:-/mattermost/config/config.json}"

# allow the container to be started with `--user`
if [[ "$*" == node*current/index.js* ]] && [ "$(id -u)" = '0' ]; then
	find "$GHOST_CONTENT" \! -user node -exec chown node '{}' +
	exec gosu node "$BASH_SOURCE" "$@"
fi

if [[ "$*" == node*current/index.js* ]]; then
	baseDir="$GHOST_INSTALL/content.orig"
	for src in "$baseDir"/*/ "$baseDir"/themes/*; do
		src="${src%/}"
		target="$GHOST_CONTENT/${src#$baseDir/}"
		mkdir -p "$(dirname "$target")"
		if [ ! -e "$target" ]; then
			tar -cC "$(dirname "$src")" "$(basename "$src")" | tar -xC "$(dirname "$target")"
		fi
	done
fi

exec "$@"
