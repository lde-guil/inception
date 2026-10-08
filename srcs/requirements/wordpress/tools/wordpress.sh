#!/bin/sh
export PHP_MEMORY_LIMIT=512M
echo "Waiting for MariaDB..."
while ! mariadb -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB is ready."

mkdir -p /srv/www/wordpress
cd /srv/www/wordpress

if [ ! -f wp-cli.phar ]; then
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
fi

if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."
    php -d memory_limit=512M wp-cli.phar core download --allow-root
    php -d memory_limit=512M wp-cli.phar config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb" \
        --allow-root

    sed -i "/\/\* That's all, stop editing/i \\\n\/\/ Redis Configuration\ndefine('WP_REDIS_HOST', 'redis');\ndefine('WP_REDIS_PORT', 6379);\ndefine('WP_REDIS_DATABASE', 0);\ndefine('WP_REDIS_TIMEOUT', 1);\ndefine('WP_REDIS_READ_TIMEOUT', 1);\n" wp-config.php
    
    php -d memory_limit=512M wp-cli.phar core install \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --allow-root
    
    php -d memory_limit=512M wp-cli.phar user create \
    "$WORDPRESS_USER" \
    "$WORDPRESS_USER_EMAIL" \
    --role=subscriber \
    --user_pass="$WORDPRESS_USER_PASSWORD" \
    --allow-root
fi

chmod 755 /srv
chmod 755 /srv/www
chmod 755 /srv/www/wordpress
find /srv/www/wordpress -type d -exec chmod 755 {} \;
find /srv/www/wordpress -type f -exec chmod 644 {} \;
chown -R nobody:nobody /srv/www/wordpress

sed -i 's|listen = 127.0.0.1:9000|listen = 9000|' /etc/php83/php-fpm.d/www.conf

echo "Starting PHP-FPM..."
exec php-fpm83 -F