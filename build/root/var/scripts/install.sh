#!/bin/sh

apk --update --no-cache add openssl tzdata nginx py-simplejson gd tiff libpng ghostscript \
php7 php7-cli php7-fpm php7-mysqli php7-pdo_mysql php7-mcrypt php7-curl php7-opcache php7-pdo \
php7-soap php7-gd php7-gmp php7-json php7-xml php7-dom php7-xmlreader php7-zlib php7-zip \
php7-phar php7-ctype php7-openssl php7-iconv php7-mbstring php7-tokenizer php7-xmlwriter php7-session \
git supervisor bash nano wget curl htop mc sudo redis mysql-client openssh openssh-sftp-server lynx bash-completion git-bash-completion

curl -sS https://getcomposer.org/installer | \
php -- --install-dir=/usr/bin --filename=composer

cd /tmp

wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-2.26-r0.apk
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-bin-2.26-r0.apk
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-i18n-2.26-r0.apk

apk add glibc-2.26-r0.apk
apk add glibc-bin-2.26-r0.apk
apk add glibc-i18n-2.26-r0.apk

rm -f glibc-2.26-r0.apk
rm -f glibc-bin-2.26-r0.apk
rm -f glibc-i18n-2.26-r0.apk

cd ~/

/usr/glibc-compat/bin/localedef -i ru_RU -f UTF-8 ru_RU.UTF-8

ssh-keygen -A
mkdir /root/.ssh

ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so


sed -i 's|logfile /var/log/redis/redis.log|logfile ""|i' /etc/redis.conf
sed -i 's|daemonize yes|daemonize no|i' /etc/redis.conf
sed -i 's|dir /var/lib/redis/|dir /var/redis/data|i' /etc/redis.conf

mkdir /logs
touch /logs/error.log
touch /logs/nginx.log
touch /logs/nginx-site.log
ln -sf /dev/stdout /logs/error.log
ln -sf /dev/stdout /logs/nginx.log
ln -sf /dev/stdout /logs/nginx-site.log

mkdir /run/nginx/
mkdir -p /var/run/php-fpm
mkdir -p /var/log/supervisor

rm -rf /var/cache/apk/*
