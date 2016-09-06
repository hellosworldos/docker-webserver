FROM ubuntu:xenial


ENV DEBIAN_FRONTEND noninteractive
ENV DISTRIBUTION_VENDOR ubuntu
ENV DISTRIBUTION_NAME xenial
ENV PHP_VERSION php7.0

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    ca-certificates \
    inotify-tools \
    pwgen \
    supervisor \
    zip \
    unzip \
    wget \
    less \
    vim \
    curl \
    procps \
    ssh \
    && apt-get clean

VOLUME ["/var/log/supervisor"]

ADD /etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y \
    ${PHP_VERSION}-common \
    ${PHP_VERSION}-fpm \
    ${PHP_VERSION}-mysql \
    ${PHP_VERSION}-intl \
    ${PHP_VERSION}-xsl \
    ${PHP_VERSION}-mbstring \
    ${PHP_VERSION}-zip \
    ${PHP_VERSION}-bcmath \
    ${PHP_VERSION}-iconv \
    ${PHP_VERSION}-curl \
    ${PHP_VERSION}-gd \
    ${PHP_VERSION}-mcrypt \
    ${PHP_VERSION}-fpm \
    ${PHP_VERSION}-cli \
    ${PHP_VERSION}-mysql \
    php-memcache \
    php-ssh2 \
    mysql-client \
    cron \
    && echo deb http://nginx.org/packages/$DISTRIBUTION_VENDOR/ $DISTRIBUTION_NAME nginx | tee /etc/apt/sources.list.d/nginx.list \
    && cd /tmp \
    && wget http://nginx.org/keys/nginx_signing.key \
    && apt-key add nginx_signing.key \
    && apt-get update \
    && apt-get install -y nginx \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

VOLUME ["/var/log/nginx", "/var/log/php-fpm"]

ADD /etc/php5/fpm/php-fpm.conf /etc/$PHP_VERSION/fpm/php-fpm.conf
ADD /etc/php5/fpm/pool.d/www.conf /etc/$PHP_VERSION/fpm/pool.d/www.conf
ADD /etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD /etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
ADD /etc/php5/conf.d/20-widgento-webserver.conf /etc/php5/conf.d/20-widgento-webserver.conf

RUN rm -rf /etc/nginx/conf.d/*

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
