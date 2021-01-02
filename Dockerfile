FROM mcr.microsoft.com/oryx/php:7.3-20190708.2

ENV PHP_VERSION 7.3

COPY init_container.sh /bin/
COPY hostingstart.html /home/site/wwwroot/hostingstart.html

RUN chmod 755 /bin/init_container.sh \
    && mkdir -p /home/LogFiles/ \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home/site/wwwroot" >> /etc/bash.bashrc \
    && ln -s /home/site/wwwroot /var/www/html \
    && mkdir -p /opt/startup

# configure startup
COPY sshd_config /etc/ssh/
COPY apache2.conf /etc/apache2/
COPY ssh_setup.sh /tmp
RUN mkdir -p /opt/startup \
   && chmod -R +x /opt/startup \
   && chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/*

RUN DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y tzdata
ENV TZ=Asia/Tokyo
RUN apt-get install tzdata

ENV PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080
COPY sshd_config /etc/ssh/

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

RUN rm -f /usr/local/etc/php/conf.d/php.ini \
   && { \
        echo 'error_log=/dev/stderr'; \
        echo 'display_errors=Off'; \
        echo 'log_errors=On'; \
        echo 'display_startup_errors=Off'; \
        echo 'date.timezone=Asia/Tokyo'; \
        echo 'zend_extension=opcache'; \
        echo 'expose_php = off'; \
        echo 'mbstring.language = Japanese'; \
        echo 'mbstring.internal_encoding = UTF-8'; \
        echo 'mbstring.http_input = pass'; \
        echo 'mbstring.http_output = pass'; \
        echo 'mbstring.encoding_translation = Off'; \
        echo 'mbstring.detect_order = auto'; \
        echo 'session.cookie_httponly = 1'; \
        echo 'session.cookie_secure = 1'; \
        echo 'session.use_cookies = 1'; \
        echo 'session.use_only_cookies = 1'; \
        echo 'zlib.output_compression = On'; \
    } > /usr/local/etc/php/conf.d/php.ini

RUN rm -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/bin/init_container.sh"]
