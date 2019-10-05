FROM ubuntu:18.04

MAINTAINER Luca Mattivi <luca@smartdomotik.com>

ARG TIMEZONE="Europe/Paris"
ARG ESPO_VERSION=5.7.0

ENV PROJECT_PATH=/var/www \
    PROJECT_URL=uala.it \
    DEBIAN_FRONTEND=noninteractive \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    PHP_MODS_CONF=/etc/php/7.2/mods-available \
    PHP_INI=/etc/php/7.2/apache2/php.ini \
    TERM=xterm

RUN apt-get update -q && apt-get upgrade -yqq && \
    apt-get install -yqq software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

# Utilities, Apache, PHP, and supplementary programs
RUN apt-get install -yqq \
    npm \
    git \
    htop \
    nano \
    wget \
    zip \
    unzip \
    apache2 \
    curl \
    cron \
    libapache2-mod-php7.2 \
    php \
    php-mbstring \
    php-mysql \
    php-json \
    php-intl \
    php-redis \
    php-soap \
    php-curl \
    php-gd \
    php-zip \
    php-imap \
    php-cgi \
    php-xml \
    openssl
#RUN ln -s "$(which nodejs)" /usr/bin/node

# Apache mods
RUN a2enmod rewrite expires headers
RUN phpenmod imap mbstring

# PHP.ini file: enable <? ?> tags and quieten logging
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" $PHP_INI && \
    sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" $PHP_INI  && \
    sed -i "s/display_errors = .*$/display_errors = On/" $PHP_INI  && \
    sed -i "s/max_execution_time = .*$/max_execution_time = 180/" $PHP_INI  && \
    sed -i "s/max_input_time = .*$/max_input_time = 180/" $PHP_INI  && \
    sed -i "s/memory_limit = .*$/memory_limit = 256M/" $PHP_INI  && \
    sed -i "s/post_max_size = .*$/post_max_size = 50M/" $PHP_INI  && \
    sed -i "s/upload_max_filesize = .*$/upload_max_filesize = 50M/" $PHP_INI

# Apache2 conf
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf && \
    a2enconf fqdn

# Set the timezone.
RUN echo $TIMEZONE > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Add our crontab file
ADD crons.conf /root/crons.conf

# VirtualHost
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

#Download ESPOCRM
WORKDIR /tmp
RUN wget https://www.espocrm.com/downloads/EspoCRM-$ESPO_VERSION.zip && \
    unzip /tmp/EspoCRM-$ESPO_VERSION.zip -d /tmp

RUN cp -a /tmp/EspoCRM-$ESPO_VERSION/. $PROJECT_PATH/

WORKDIR $PROJECT_PATH

# Folder permissions & Add permissions for temp data of mpdf library
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP . && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP data/ && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP custom/ && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP client/custom/ && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP application/Espo/Modules/ && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP client/modules/ && \
    mkdir logs && chown -R $APACHE_RUN_USER:root logs/

RUN find . -type d -exec chmod 755 {} + && find . -type f -exec chmod 644 {} +;
RUN find data custom -type d -exec chmod 775 {} + && find data custom -type f -exec chmod 664 {} +;
RUN chmod 777 cron.php

# Cleanup
RUN apt-get purge -yq \
      wget \
      patch \
      software-properties-common && \
    apt-get autoremove -yqq

# Port to expose
EXPOSE 80

RUN crontab /root/crons.conf

# Remove pre-existent apache pid and start apache
CMD rm -f $APACHE_PID_FILE && cron && /usr/sbin/apache2ctl -D FOREGROUND
