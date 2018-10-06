#!/bin/bash

# internal variables
user_chars='abcdefghijklmnopqrstuvwxyz'
password_chars='abcdefghijklmnopqrstuvwxyz0123456789!@#%^-_'

define_vars() {
    export DB_HOST='db'
    export DB_NAME='lifecycledb'
    export DB_USER=$(python -c "import random; print(''.join(random.choice('${user_chars}') for i in range(7)))")
    export DB_PASSWORD=$(python -c "import random; print(''.join(random.choice('${password_chars}') for i in range(10)))")
    export EMAIL_HOST='mail'
    export EMAIL_PORT=1025
    export MYSQL_ROOT_PASSWORD=$(python -c "import random; print(''.join(random.choice('${password_chars}') for i in range(10)))")
}

write_out_env() {
    local env_var
    local all_vars="DB_HOST DB_NAME DB_USER DB_PASSWORD \
    EMAIL_HOST EMAIL_PORT MYSQL_ROOT_PASSWORD"

    for env_var in ${all_vars}; do
        echo "export ${env_var}='${!env_var}'"
    done
} > "${env_file}"

env_file='./.test.env'
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
