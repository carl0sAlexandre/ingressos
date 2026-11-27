ARG BASE_IMAGE=php:8.4-fpm
FROM ${BASE_IMAGE}

ARG APP_DIR=/var/www
ARG APP_VERSAO
ENV APP_VERSAO='123abc'

RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    unzip \
    libpng-dev \
    libpq-dev \
    libxml2-dev

RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

RUN pecl install redis \
    && docker-php-ext-enable redis 

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install zip gd

RUN apt-get update; \
    apt-get install -y\
        libicu-dev; \
    docker-php-ext-install intl; \
    rm -rf /var/lib/apt/lists/*;

RUN docker-php-ext-enable opcache || true

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# RUN apt-get update && apt-get install -y \
# 		libfreetype-dev \
# 		libjpeg62-turbo-dev \
# 		libpng-dev \
# 	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
# 	&& docker-php-ext-install -j$(nproc) gd