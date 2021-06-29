FROM php:7.4-fpm-alpine3.14

ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv \
    && apk add --no-cache --virtual .build-deps \
    autoconf \
    gcc \
    libc-dev \
    make \
    libressl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev

RUN echo @testing http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    echo http://dl-cdn.alpinelinux.org/alpine/latest-stable/community >> /etc/apk/repositories && \
    echo /etc/apk/respositories && \
    apk update && apk upgrade &&\
    apk add --no-cache \
    bash \
    openssh-client \
    wget \
    supervisor \
    curl \
    libcurl \
    libzip-dev \
    bzip2-dev \
    imap-dev \
    openssl-dev \
    git \
    python \
    python-dev \
    py-pip \
    augeas-dev \
    libressl-dev \
    ca-certificates \
    dialog \
    autoconf \
    make \
    gcc \
    musl-dev \
    linux-headers \
    libmcrypt-dev \
    libpng-dev \
    icu-dev \
    libpq \
    libxslt-dev \
    libffi-dev \
    freetype-dev \
    sqlite-dev \
    libjpeg-turbo-dev \
    postgresql-dev \
    nano \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    tzdata && \
    docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install pdo_mysql bcmath pgsql pdo_pgsql mysqli gd exif intl xsl soap zip opcache && \
    pecl install xdebug-2.7.2 && \
    pecl install -o -f redis && \
    echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini && \
    docker-php-ext-enable xdebug && \
    docker-php-source delete && \
    mkdir -p /var/log/supervisor && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --quiet --install-dir=/usr/bin --filename=composer && \
    rm composer-setup.php && \
    apk del gcc musl-dev linux-headers libffi-dev augeas-dev python-dev make autoconf && \
    cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    echo "Europe/Moscow" > /etc/timezone && \
    apk del tzdata

RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
    echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
    echo "post_max_size = 100M"  >> ${php_vars} &&\
    echo "variables_order = \"EGPCS\""  >> ${php_vars} && \
    echo "memory_limit = 1024M"  >> ${php_vars} && \
    echo "max_file_uploads = 100"  >> ${php_vars} && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/^;slowlog =/slowlog =/g" \
        -e "s/;request_slowlog_timeout = 0/request_slowlog_timeout = 3s/g" \
        -e "s/;request_slowlog_trace_depth = 20/request_slowlog_trace_depth = 20/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf} && \
    mkdir /usr/local/log && \
    chmod 775 /usr/local/log

ADD etc/supervisord.conf /etc/supervisord.conf

EXPOSE 9000

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
