#!/bin/sh


sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini \
&& sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini \
&& sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini \
&& sed -i "s|max_execution_time = 30|max_execution_time = ${PHP_MAX_EXECUTION_TIME}|i" /etc/php7/php.ini \
&& sed -i "s|default_socket_timeout = 60|default_socket_timeout = ${PHP_DEFAULT_SOCKET_TIMEOUT}|i" /etc/php7/php.ini \
&& sed -i "s|memory_limit = 128M|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini \
&& sed -i "s|; max_input_vars = 1000|max_input_vars = ${PHP_MAX_INPUT_VARS}|i" /etc/php7/php.ini \
&& sed -i "s|;date.timezone =|date.timezone = $TZ|i" /etc/php7/php.ini \
&& sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini \
&& sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini \
&& sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini \
&& sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini \
&& sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${USER}|g" /etc/php7/php-fpm.d/www.conf \
&& sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${GROUP}|g" /etc/php7/php-fpm.d/www.conf \
&& sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.d/www.conf \
&& sed -i "s|user\s*=\s*nobody|user = ${USER}|g" /etc/php7/php-fpm.d/www.conf \
&& sed -i "s|group\s*=\s*nobody|group = ${GROUP}|g" /etc/php7/php-fpm.d/www.conf \
&& sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.conf \
&& sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf \
&& sed -i "s|user www;|user ${USER};|i" /etc/nginx/nginx.conf 

cp /usr/share/zoneinfo/${TZ} /etc/localtime
echo "${TZ}" > /etc/timezone

chmod -R 664 /www
chmod 777 /www

adduser -D -h /www -s /bin/bash ${USER}
chown -R ${USER}:${GROUP} /www
chown -R ${USER}:${GROUP} /var/lib/nginx
su - ${USER} -c "composer global require 'laravel/installer'"
su - ${USER} -c "mkdir ~/.ssh"


su - ${USER} -c "mkdir ~/pma  && \
cd ~/pma && \
wget https://files.phpmyadmin.net/phpMyAdmin/4.7.7/phpMyAdmin-4.7.7-all-languages.tar.gz && \
tar -xzf phpMyAdmin-4.7.7-all-languages.tar.gz -C ~/pma --strip 1 && \
rm -f phpMyAdmin-4.7.7-all-languages.tar.gz && \
cp config.sample.inc.php config.inc.php"

sed -i "s|\$cfg\['blowfish_secret'\] = '';*|\$cfg\['blowfish_secret'\] = '23452857238rg8gblyug123pcbf5o912v65o871}P}:cf57109823b2f50';|i" /www/pma/config.inc.php

sed -i "s|export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin|export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$HOME/.composer/vendor/bin|i" /etc/profile

echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "${USER}:${USER_PASSWORD}"|chpasswd

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s|worker_processes 1|worker_processes $procs|" /etc/nginx/nginx.conf


mkdir -p /var/redis/data
chown -R redis:redis /var/redis/data
echo -e "include /etc/redis-local.conf\n" >> /etc/redis.conf

# parameters
MYSQL_ROOT_PWD=${MYSQL_ROOT_PWD:-"mysql"}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_USER_PWD=${MYSQL_USER_PWD:-""}
MYSQL_USER_DB=${MYSQL_USER_DB:-""}

if [ ! -d "/run/mysqld" ]; then
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
	echo '[i] MySQL directory already present, skipping creation'
else
	echo "[i] MySQL data directory not found, creating initial DBs"

	chown -R mysql:mysql /var/lib/mysql

	# init database
	echo 'Initializing database'
	mysql_install_db --user=mysql > /dev/null
	echo 'Database initialized'

	echo "[i] MySql root password: $MYSQL_ROOT_PWD"

	# create temp file
	tfile=`mktemp`
	if [ ! -f "$tfile" ]; then
	    return 1
	fi

	# save sql
	echo "[i] Create temp file: $tfile"
	cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.user;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION;
EOF


	# Create new database
	if [ "$MYSQL_USER_DB" != "" ]; then
		echo "[i] Creating database: $MYSQL_USER_DB"
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_USER_DB\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

		# set new User and Password
		if [ "$MYSQL_USER" != "" ] && [ "$MYSQL_USER_PWD" != "" ]; then
		echo "[i] Creating user: $MYSQL_USER with password $MYSQL_USER_PWD"
		echo "GRANT ALL ON \`$MYSQL_USER_DB\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';" >> $tfile
		fi
	else
		# don`t need to create new database,Set new User to control all database.
		if [ "$MYSQL_USER" != "" ] && [ "$MYSQL_USER_PWD" != "" ]; then
		echo "[i] Creating user: $MYSQL_USER with password $MYSQL_USER_PWD"
		echo "GRANT ALL ON *.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';" >> $tfile
		fi
	fi

	echo 'FLUSH PRIVILEGES;' >> $tfile

	# run sql in tempfile
	echo "[i] run tempfile: $tfile"
	/usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
	rm -f $tfile
fi

echo "[i] Sleeping 5 sec"
sleep 5

echo '[i] start running services'


exec supervisord -c /etc/supervisord.conf
