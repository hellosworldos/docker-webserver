FROM ubuntu:xenial
MAINTAINER Yury Ksenevich <yury@spadar.com>


ENV DEBIAN_FRONTEND noninteractive
ENV DISTRIBUTION_VENDOR ubuntu
ENV DISTRIBUTION_NAME xenial
ENV PHP_VERSION 7.0
ENV COMPOSER_ASSET_PLUGIN_VER 1.2.2
ENV UPLOAD_LIMIT 256
ENV NODEJS_VERSION 6.x
ENV BUILD_LOCALE en_US
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# @TODO debug it later
#RUN localedef -c -f UTF-8 -i ${BUILD_LOCALE} ${LANG} \
#    && locale-gen en ${BUILD_LOCALE} ${LANG} \
#    && dpkg-reconfigure locales

# Install tools
RUN apt-get -qy update --fix-missing \
    && apt-get -qqy upgrade \
    && apt-get install -qqy \
    software-properties-common \
    python-software-properties \
    python-setuptools

# Install base packages
RUN apt-get -y update --fix-missing \
    && apt-get -y upgrade \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    vim \
    make \
    git-core \
    wget \
    curl \
    procps \
    mcrypt \
    mysql-client \
    zip \
    unzip \
    redis-tools \
    netcat-openbsd \
    inotify-tools \
    pwgen \
    supervisor \
    vim \
    ssh \
    mysql-client \
    cron \
    gettext-base \
    && apt-get clean -qq

VOLUME ["/var/log/supervisor"]

ADD /etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Install php
RUN apt-get -y update --fix-missing \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
    php-common \
    php-fpm \
    php-mysql \
    php-intl \
    php-xsl \
    php-mbstring \
    php-zip \
    php-bcmath \
    php-iconv \
    php-curl \
    php-gd \
    php-mcrypt \
    php-fpm \
    php-cli \
    php-mysql \
    php-dev \
    php-xmlrpc \
    php-ldap \
    php-soap \
    php-bz2 \
    php-redis \
    php-tidy \
    php-memcache \
    php-xdebug \
    php-ssh2 \
    && rm -rf /etc/php/${PHP_VERSION}/fpm/conf.d/20-xdebug.ini \
    && rm -rf /etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini \
    && mkdir -p /var/log/php/xdebug \
    && apt-get clean -qq

# Install composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer.phar \
    # Create composer home dirs
    && mkdir -p -m 0744 /opt/composer/root \
    && mkdir -p -m 0744 /opt/composer/www-data \
    && chown www-data:www-data /opt/composer/www-data \
    # Create composer wrapper
    && echo '#!/usr/bin/env bash' >> /usr/local/bin/composer \
    && echo 'COMPOSER_HOME=/opt/composer/$(whoami) /usr/local/bin/composer.phar $@' >> /usr/local/bin/composer \
    && chmod 0755 /usr/local/bin/composer \
    # Install required composer-plugins
    && runuser -s /bin/sh -c 'composer global require fxp/composer-asset-plugin:${COMPOSER_ASSET_PLUGIN_VER}' www-data

# Install nginx
RUN echo deb http://nginx.org/packages/${DISTRIBUTION_VENDOR}/ ${DISTRIBUTION_NAME} nginx | tee /etc/apt/sources.list.d/nginx.list \
    && cd /tmp \
    && wget http://nginx.org/keys/nginx_signing.key \
    && apt-key add nginx_signing.key \
    && apt-get update \
    && apt-get install -y nginx \
    && apt-get clean -qq

VOLUME ["/var/log/nginx", "/var/log/php-fpm"]

ADD etc/php/fpm/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
ADD etc/php/fpm/pool.d/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
ADD etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
ADD etc/php/fpm/conf.d/20-widgento-webserver.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-widgento-webserver.ini
ADD etc/php/fpm/conf.d/20-xdebug.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-xdebug.ini.dist
ADD etc/php/cli/conf.d/20-widgento-webserver.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-widgento-webserver.ini
ADD etc/php/cli/conf.d/20-xdebug.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini.dist

RUN rm -rf /etc/nginx/conf.d/* \
    && envsubst '${UPLOAD_LIMIT}' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf \
    && envsubst '${PHP_VERSION}' < /etc/php/${PHP_VERSION}/cli/conf.d/20-widgento-webserver.ini > /etc/php/${PHP_VERSION}/cli/conf.d/20-widgento-webserver.ini \
    && envsubst '${PHP_VERSION}' < /etc/php/${PHP_VERSION}/fpm/conf.d/20-widgento-webserver.ini > /etc/php/${PHP_VERSION}/fpm/conf.d/20-widgento-webserver.ini \
    && envsubst '${PHP_VERSION}' < /etc/php/${PHP_VERSION}/fpm/php-fpm.conf > /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
    && envsubst '${PHP_VERSION}' < /etc/supervisor/conf.d/nginx.conf > /etc/supervisor/conf.d/nginx.conf

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
