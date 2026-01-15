#!/bin/bash

# Set ownership and permissions for WordPress files so that PHP-FPM (www-data)
# can read and write content securely (uploads, plugins, cache, etc.)
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Update WordPress site URLs in the database;
# --allow-root is required because WP-CLI runs as root inside the container
# and '|| true' prevents the script from failing if the update command returns an error
update_wp_urls() {
    SCHEME="https"
    if [ "${PORT}" = "443" ] || [ -z "${PORT}" ]; then
        URL="${SCHEME}://${DOMAIN_NAME}"
    else
        URL="${SCHEME}://${DOMAIN_NAME}:${PORT}"
    fi
    echo "Updating WordPress URLs to: ${URL}"
    wp option update home "${URL}" --allow-root || true
    wp option update siteurl "${URL}" --allow-root || true
}

if [ ! -f wp-config.php ]; then

    wp core download --allow-root

    DB_ON=false

    for i in $(deq 1 30); do
        if mysqladmin ping -h mariadb --silent; then
            DB_ON=true
            break
        fi
        encho "Waiting for MariaDB... ($i/30)"
        sleep 2
    done

    if [ "$DB_ON" = false ]; then
        echo " Error: MariaDB not reachable"
        exit 1
     
    echo "Creating wp-config.php"
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=${MYSQL_HOSTNAME} \
        --allow-root