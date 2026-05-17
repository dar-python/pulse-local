FROM php:8.4-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache \
    bash \
    git \
    curl \
    unzip \
    icu-dev \
    libzip-dev \
    mysql-client

RUN docker-php-ext-install \
    intl \
    pdo_mysql \
    bcmath \
    zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./

RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

COPY . .

RUN composer dump-autoload --optimize \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

COPY docker/php/entrypoint.sh /usr/local/bin/pulselocal-laravel-entrypoint
RUN chmod +x /usr/local/bin/pulselocal-laravel-entrypoint

EXPOSE 9000

ENTRYPOINT ["pulselocal-laravel-entrypoint"]
CMD ["php-fpm"]
