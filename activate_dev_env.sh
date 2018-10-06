#!/bin/bash

# internal variables
secret_key_chars='abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
user_chars='abcdefghijklmnopqrstuvwxyz'
password_chars='abcdefghijklmnopqrstuvwxyz0123456789!@#%^-_'

define_vars() {
    # celery variable
    export C_FORCE_ROOT=1

    # django variables
    export SECRET_KEY=$(python -c "import random; print(''.join(random.choice('${secret_key_chars}') for i in range(50)))")
    export DB_HOST='db'
    export DB_NAME='lifecycledb'
    export DB_USER=$(python -c "import random; print(''.join(random.choice('${user_chars}') for i in range(7)))")
    export DB_PASSWORD=$(python -c "import random; print(''.join(random.choice('${password_chars}') for i in range(10)))")
    export DJANGO_SETTINGS_MODULE='lifecycle.settings.local'
    export EMAIL_HOST='mail'
    export EMAIL_PORT=1025
    export INTERNAL_IP='172.20.1.1'
    export REDIS_HOST='redis'

    # mailhog variables
    export MH_OUTGOING_SMTP='/home/wasadmin/smtp-servers.json'

    # mariadb variables
    export MYSQL_ROOT_PASSWORD=$(python -c "import random; print(''.join(random.choice('${password_chars}') for i in range(10)))")
}

write_out_env() {
    local env_var
    local all_vars="C_FORCE_ROOT DB_HOST DB_NAME DB_USER DB_PASSWORD \
    DJANGO_SETTINGS_MODULE EMAIL_HOST EMAIL_PORT INTERNAL_IP REDIS_HOST \
    MH_OUTGOING_SMTP MYSQL_ROOT_PASSWORD SECRET_KEY"

    for env_var in ${all_vars}; do
        echo "export ${env_var}='${!env_var}'"
    done
} > "${env_file}"

env_file='./.middleware-lifecycle.env'
if [ -e "${env_file}" ]; then
    read -p "${env_file} already exists, overwrite? [YyNn]: " answer
    case "${answer}" in
        Y|y)
            { define_vars; }
            write_out_env
            ;;
        N|n)
            { source "${env_file}"; }
            ;;
        *)
            exit 4
            ;;
    esac
else
    { define_vars; }
    write_out_env
    echo "Saved env vars to ${env_file}"
fi
