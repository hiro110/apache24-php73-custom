FROM php:7.3-apache

RUN a2enmod rewrite expires include deflate headers remoteip

RUN DEBIAN_FRONTEND=noninteractive
RUN apt install -y tzdata
ENV TZ=Asia/Tokyo
RUN apt install -y tzdata

RUN apt update \
        && apt install -y --no-install-recommends \
        # # libpng-dev \
        # # libjpeg-dev \
        # # libpq-dev \
        # # libmcrypt-dev \
        # # libldap2-dev \
        # # libldb-dev \
        # # libicu-dev \
        # # libgmp-dev \
        imagemagick libmagickwand-dev \
        vim wget \
        # # openssh-server vim curl wget tcptraceroute \
        # # && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
        # # && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
        # # && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
        # && rm -rf /var/lib/apt/lists/* \
        # && pecl install imagick \
        # && pecl install mcrypt-1.0.4 \
        # && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install -j$(nproc) gd mysqli opcache pdo_mysql
        # pdo_pgsql \
        # pgsql \
        # intl \
        # gmp \
        # zip \
        # gd \
        # && docker-php-ext-enable imagick
        # && docker-php-ext-enable mcrypt

COPY init_container.sh /bin/
COPY hostingstart.html /home/site/wwwroot/hostingstart.html
COPY index.php /home/site/wwwroot/index.php

RUN chmod 755 /bin/init_container.sh \
    && mkdir -p /home/LogFiles/ \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home/site/wwwroot" >> /etc/bash.bashrc \
    && ln -s /home/site/wwwroot /var/www/html \
    && mkdir -p /opt/startup

# configure ssh
COPY sshd_config /etc/ssh/

# configure apache
COPY apache2.conf /etc/apache2/

# configure php
RUN echo 'error_log=/dev/stderr' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'display_startup_errors=Off' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'date.timezone=Asia/Tokyo' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.language = Japanese' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.internal_encoding = UTF-8' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.http_input = pass' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.http_output = pass' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.encoding_translation = Off' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'mbstring.detect_order = auto' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'session.cookie_httponly = 1' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'session.cookie_secure = 1' >> /usr/local/etc/php/conf.d/php.ini \
    && sed -i "s/expose_php = On/expose_php = off/g" /usr/local/etc/php/conf.d/php.ini \
    && sed -i "s/zlib.output_compression = Off/zlib.output_compression = On/g" /usr/local/etc/php/conf.d/php.ini

COPY ssh_setup.sh /tmp
RUN mkdir -p /opt/startup \
    && chmod -R +x /opt/startup \
    && chmod -R +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
    && rm -rf /tmp/*

ENV APACHE_PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080

ENV APACHE_RUN_USER www-data
ENV PHP_VERSION 7.3
ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/bin/init_container.sh"]
