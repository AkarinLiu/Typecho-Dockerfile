ARG TAG=latest
FROM php:$TAG

# default download latest dev version
ARG URL="https://nightly.link/typecho/typecho/workflows/Typecho-dev-Ci/master/typecho_build.zip"

# install bash
COPY --chown=root:root ./scripts/install-bash.sh .
RUN ./install-bash.sh

# define function
COPY --chown=root:root ./scripts/use.sh /bin/use

# update
RUN `use "apt-get update" "apk update"`

# install dependencies
RUN `use "apt-get install -y" "apk add"` \
    `use libfreetype6-dev freetype-dev` \
    `use libjpeg62-turbo-dev libjpeg-turbo-dev` \
    `use libpq-dev postgresql-dev` \
    libpng-dev \
    libzip-dev \
    libwebp-dev \
    curl \
    unzip

# install extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        zip \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        sockets \
        tokenizer \
        opcache

# config php error handler
RUN { \
        echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# download source code
RUN curl -o typecho.zip -fL $URL \
    && unzip typecho.zip -d /app \
    && mkdir /app/usr/uploads && chmod 777 /app/usr/uploads \
    && rm -rf typecho.zip

# download langs
RUN curl -o langs.zip -fL https://nightly.link/typecho/languages/workflows/ci/master/langs.zip \
    && unzip langs.zip -d /app/usr/langs \
    && rm -rf langs.zip

RUN chown -Rf www-data:www-data /app

VOLUME /app/usr
WORKDIR /app