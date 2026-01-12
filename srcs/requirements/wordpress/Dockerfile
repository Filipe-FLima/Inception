FROM debian:bookworm

# Install necessary package from php
RUN apt-get update && apt-get install -y \
	wget \
	curl \
	php8.2-gd \
	php8.2-xml \
	php8.2-fpm \
	php8.2-curl \
	php8.2-mysql \
	mariadb-client \
	php8.2-mbstring && \
	rm -rf /var/lib/apt/lists/*

# Install WP-CLI for automated WordPress management
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy the .conf into php-fpm pool directory
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy the script, give the right to execute it in local on our computer
COPY ./tools/wp-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-setup.sh
ENTRYPOINT ["/usr/local/bin/wp-setup.sh"]

WORKDIR /var/www/html

EXPOSE 9000

# test it
CMD ["php-fpm8.2", "-F"]