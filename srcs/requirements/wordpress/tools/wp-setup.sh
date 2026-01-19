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

    for i in $(seq 1 30); do
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

    echo "Installing WP"
    wp core install \
        --url=${DOMAIN_NAME} \
        --title="42INCEPTION" \
        --admin-user=${WP_ADMIN} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --allow-root
    
    #install theme

    echo "Creating user account"
    wp user create / 
        ${WP_USER} ${WP_USER_EMAIL} \
        --user_pass=${WP_USER_PW} \
        --role=author \
        --allow-root
    
    update_wp_urls

    echo "WP setup completed successfully"

else
    echo "WP is already set up"
    update_wp_urls
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F