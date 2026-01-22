#!/bin/bash

set -eu

SOCKET_DIR = /run/mysqld
SOCKET = "${SOCKET_DIR}/mysqld.sock}"
DATA_DIR = "/var/lib/mysql"

mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}" "${DATA_DIR}"

#first run: check if volume empty \ DB not initialized
if [ ! -d "${DATA_DIR}/mysql"]; then
    echo "Installing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir="${DATA_DIR}" >/dev/null
fi

if [ ! -d "${DATA_DIR}/${MYSQL_DATABASE}"]; then
    
    service mariadb start;

    mysql -e "CREATE DATABASE IF NOT EXISTS \'${MYSQL_DATABASE}\';"