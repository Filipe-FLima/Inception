#!/bin/bash

set -eu

SOCKET_DIR=/run/mysqld
SOCKET="${SOCKET_DIR}/mysqld.sock"
DATA_DIR="/var/lib/mysql"

mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}" "${DATA_DIR}"

#first run: check if volume empty \ DB not initialized
if [ ! -d "${DATA_DIR}/mysql" ]; then
    echo "Installing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir="${DATA_DIR}" >/dev/null
fi

# bootstrap once mariadb if the database does not exist yet
if [ ! -d "${DATA_DIR}/${MYSQL_DATABASE}" ]; then
    
    #start mariadb temporary to set local conf
    mysqld --user=mysql --datadir="${DATA_DIR}" --socket="${SOCKET}" --skip-networking &
    
    #salve last PID run in background
    TEMP_PID="$!"

    MAX_ATTEMPTS=20
    i=0
    while ! mysqladmin --protocol=socket --socket="${SOCKET}" ping --silent; do
        i=$((i+1))
        if [ "$i" -ge "$MAX_ATTEMPTS" ]; then
            kill "$TEMP_PID" 2>/dev/null || true
            echo "Error: MarriaDB initialization timeout"
            exit 1
        fi
        echo "Waiting for mariaDB initialization... (${i}/${MAX_ATTEMPTS})"
        sleep 1
    done

    # Run bootstrap SQL
    mysql --protocol=socket --socket="${SOCKET}" -u root <<-SQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PW}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
SQL

    #Stop temporary server mariaDB
    mysqladmin --protocol=socket --socket="${SOCKET}" -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    wait "$TEMP_PID" 2>/dev/null || true

    echo "Data base initialization complete."

else
    echo "Data base already initialized."
fi

echo "Starting MariaDB database..."
exec mysqld --user=mysql --datadir="${DATA_DIR}" --socket="${SOCKET}" "$@"