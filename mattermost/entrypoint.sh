#!/bin/bash

# Function to generate a random salt
generate_salt() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1
}

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
	export "$var"="$val"
	unset "$fileVar"
}

# Read environment variables or set default values
DB_HOST="${DB_HOST:-db}"
DB_PORT_NUMBER="${DB_PORT_NUMBER:-5432}"
file_env 'MM_USERNAME' 'mmuser'
file_env 'MM_PASSWORD' 'mmuser_password'
file_env 'MM_DBNAME' 'mattermost'
MM_CONFIG="${MM_CONFIG:-/mattermost/config/config.json}"

if [ "${1:0:1}" = '-' ]; then
    set -- mattermost "$@"
fi

if [ "$1" = 'mattermost' ]; then
  # Check CLI args for a -config option
  for ARG in $@;
  do
      case "$ARG" in
          -config=*)
              MM_CONFIG=${ARG#*=};;
      esac
  done

  if [ ! -f $MM_CONFIG ]
  then
    # If there is no configuration file, create it with some default values
    echo "No configuration file" $MM_CONFIG
    echo "Creating a new one"
    # Copy default configuration file
    cp /config.json.save $MM_CONFIG
    # Substitue some parameters with jq
    jq '.ServiceSettings.ListenAddress = ":8000"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.LogSettings.EnableConsole = false' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.LogSettings.ConsoleLevel = "INFO"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.FileSettings.Directory = "/mattermost/data/"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.FileSettings.EnablePublicLink = true' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.FileSettings.PublicLinkSalt = "'$(generate_salt)'"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.SendEmailNotifications = false' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.FeedbackEmail = ""' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.SMTPServer = ""' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.SMTPPort = ""' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.InviteSalt = "'$(generate_salt)'"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.EmailSettings.PasswordResetSalt = "'$(generate_salt)'"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.RateLimitSettings.Enable = true' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.SqlSettings.DriverName = "postgres"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.SqlSettings.AtRestEncryptKey = "'$(generate_salt)'"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG
    jq '.PluginSettings.Directory = "/mattermost/plugins/"' $MM_CONFIG > $MM_CONFIG.tmp && mv $MM_CONFIG.tmp $MM_CONFIG

    # Configure database access
    if [[ -z "$MM_SQLSETTINGS_DATASOURCE" ]]
    then
      echo -ne "Configure database connection..."
      # URLEncode the password, allowing for special characters
      ENCODED_PASSWORD=$(printf %s $MM_PASSWORD | jq -s -R -r @uri)
      export MM_SQLSETTINGS_DATASOURCE="postgres://$MM_USERNAME:$ENCODED_PASSWORD@$DB_HOST:$DB_PORT_NUMBER/$MM_DBNAME?sslmode=disable&connect_timeout=10"
      echo OK
    else
      echo "Using existing database connection"
    fi
  else
    echo "Using existing config file" $MM_CONFIG
  fi

  # Wait another second for the database to be properly started.
  # Necessary to avoid "panic: Failed to open sql connection pq: the database system is starting up"
  sleep 1

  echo "Starting mattermost"
fi

exec "$@"