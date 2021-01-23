FROM alpine:3.12

RUN apk update \
    && apk --no-cache add \
        vim curl wget git tcptraceroute bind-tools tcpdump bash \
        apache2 php7-apache2 \
        php7-curl \
        php7-ctype \
        php7-dev \
        php7-dom \
        php7-embed \
        php7-exif \
        php7-gd \
        php7-intl \
        php7-mbstring \
        php7-mysqli \
        php7-opcache \
        php7-openssl \
        php7-pdo \
        php7-pdo_mysql \
        php7-pecl-redis \
        php7-phar \
        php7-json \
        php7-session \
        php7-xml \
        php7-xmlreader \
        php7-zip

RUN apk --no-cache add tzdata \
    && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apk del tzdata

RUN mkdir -p /home/site/wwwroot \
    && mkdir -p /home/LogFiles/ \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home/site/wwwroot" >> /etc/bash.bashrc \
    && rm -rf /var/www/localhost/htdocs \
    && ln -s /home/site/wwwroot /var/www/localhost/htdocs \
    && mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf.bk \
    && mkdir -p /opt/startup \
    && chmod -R +x /opt/startup

COPY init_container.sh /bin/
# COPY hostingstart.html /home/site/wwwroot/
COPY index.php /home/site/wwwroot/
RUN chmod 755 /bin/init_container.sh

# configure ssh
COPY sshd_config /etc/ssh/

# # configure apache
COPY httpd.conf /etc/apache2/

# configure php
RUN echo 'error_log=/dev/stderr' >> /etc/php7/php.ini \
    && echo 'display_startup_errors=Off' >> /etc/php7/php.ini \
    && echo 'date.timezone=Asia/Tokyo' >> /etc/php7/php.ini \
    && sed -i "s/;mbstring.language = Japanese/mbstring.language = Japanese/g" /etc/php7/php.ini \
    && sed -i "s/;mbstring.internal_encoding =/mbstring.internal_encoding = UTF-8/g" /etc/php7/php.ini \
    && sed -i "s/;mbstring.http_input =/mbstring.http_input = pass/g" /etc/php7/php.ini \
    && sed -i "s/;mbstring.http_output =/mbstring.http_output = pass/g" /etc/php7/php.ini \
    && sed -i "s/;mbstring.encoding_translation = Off/mbstring.encoding_translation = Off/g" /etc/php7/php.ini \
    && sed -i "s/;mbstring.detect_order = auto/mbstring.detect_order = auto/g" /etc/php7/php.ini \
    && sed -i "s/session.cookie_httponly =/session.cookie_httponly = 1/g" /etc/php7/php.ini \
    && sed -i "s/;session.cookie_secure =/session.cookie_secure = 1/g" /etc/php7/php.ini \
    && sed -i "s/expose_php = On/expose_php = off/g" /etc/php7/php.ini \
    && sed -i "s/zlib.output_compression = Off/zlib.output_compression = On/g" /etc/php7/php.ini

RUN sed -i "s/;opcache.enable=1/opcache.enable=1/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.optimization_level=0x7FFFBFFF/opcache.optimization_level=0x7FFFBFFF/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.validate_timestamps=1/opcache.validate_timestamps=1/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.memory_consumption=128/opcache.memory_consumption=128/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/g" /etc/php7/php.ini \
    && sed -i "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=4000/g" /etc/php7/php.ini

COPY ssh_setup.sh /tmp
RUN chmod -R +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
    && rm -rf /tmp/*

ENV APACHE_PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080

ENV PHP_VERSION 7.3
ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/bin/init_container.sh"]
