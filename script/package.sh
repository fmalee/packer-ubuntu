#!/bin/bash -eux

SSH_USERNAME=${SSH_USERNAME:-vagrant}
SSH_PASSWORD=${SSH_PASSWORD:-vagrant}
MYSQL_APT=${MYSQL_APT:-0.7.2-1}

if [[ $LNMP  =~ true || $LNMP =~ 1 || $LNMP =~ yes ]]; then
    echo "==> Adding Apt Repository(PHP & Nginx & MySQL & Blackfire)"
	# 添加add-apt-repository命令
	apt-get -y install software-properties-common
	# PHP 7.0源
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php-qa
	# Nginx源
	add-apt-repository -y ppa:nginx/development
	# Mysql5.7源
	# sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5 
	# echo "deb http://repo.mysql.com/apt/ubuntu/ precise mysql-5.7" | sudo tee /etc/apt/sources.list.d/mysql.list
	sudo wget -P /tmp http://repo.mysql.com/mysql-apt-config_${MYSQL_APT}_all.deb
	sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-router select none'
	sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-connector-python select none'
	sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-workbench select none'
	sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select mysql-5.7'
	sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-mysql-utilities select mysql-utilities-1.5'
	sudo DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config_${MYSQL_APT}_all.deb
	# Blackfire源
	wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
	echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list
fi

echo "==> Updating the package list"
echo $UPDATE_PROXY
if [[ $UPDATE_PROXY == false || $UPDATE_PROXY == 0 || $UPDATE_PROXY == no ]]; then
	apt-get -y update
else
	echo "==> Updating with proxy"
	apt-get -y -o Acquire::http::proxy="$UPDATE_PROXY" update
fi

echo "==> Installing software(Include Packages)"
# 安装语言包
apt-get install -y language-pack-en-base language-pack-zh-hans
# 安装之前'pkgsel/include'忽略的软件
apt-get -y install build-essential gcc make
apt-get -y install zlib1g-dev libssl-dev libreadline-dev libyaml-dev
apt-get -y install cryptsetup
# apt-get -y install linux-source
apt-get -y install dkms
apt-get -y install nfs-common
# 其他常用软件
apt-get -y install vim curl wget python

if [[ $LNMP  =~ true || $LNMP =~ 1 || $LNMP =~ yes ]]; then
	echo "==> Installing LNMP & ZSH & Blackfire"

	apt-get install -y php7.0 php7.0-fpm php7.0-common
	apt-get install -y php7.0-opcache php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-curl php7.0-intl php7.0-mbstring
	apt-get install -y php7.0-zip php7.0-imap php7.0-sqlite3 php7.0-pgsql php7.0-soap php7.0-json php7.0-xml php7.0-bcmath
	apt-get install -y php-xdebug
	# PHP 7.0
	sed -i "s/^[;]*date.timezone\([[:space:]]*\)=\([[:space:]]*\).*/date.timezone = PRC/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/^upload_max_filesize\([[:space:]]*\)=\([[:space:]]*\).*/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/[;]*cgi.fix_pathinfo\([[:space:]]*\)=\([[:space:]]*\).*/cgi.fix_pathinfo = 0/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/^post_max_size\([[:space:]]*\)=\([[:space:]]*\).*/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/^display_errors\([[:space:]]*\)=\([[:space:]]*\).*/display_errors = On/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/^error_reporting\([[:space:]]*\)=\([[:space:]]*\).*/error_reporting = E_ALL/g" /etc/php/7.0/fpm/php.ini
	sed -i "s/^memory_limit\([[:space:]]*\)=\([[:space:]]*\).*/memory_limit = 512M/g" /etc/php/7.0/fpm/php.ini

	sed -i "s/[;]*date.timezone\([[:space:]]*\)=\([[:space:]]*\).*/date.timezone = PRC/g" /etc/php/7.0/cli/php.ini
	sed -i "s/^display_errors\([[:space:]]*\)=\([[:space:]]*\).*/display_errors = On/g" /etc/php/7.0/cli/php.ini
	sed -i "s/^error_reporting\([[:space:]]*\)=\([[:space:]]*\).*/error_reporting = E_ALL/g" /etc/php/7.0/cli/php.ini
	sed -i "s/^memory_limit\([[:space:]]*\)=\([[:space:]]*\).*/memory_limit = 512M/g" /etc/php/7.0/cli/php.ini

	sed -i "s/^user\([[:space:]]*\)=\([[:space:]]*\).*/user = $SSH_USERNAME/g" /etc/php/7.0/fpm/pool.d/www.conf
	sed -i "s/^group\([[:space:]]*\)=\([[:space:]]*\).*/group = $SSH_USERNAME/g" /etc/php/7.0/fpm/pool.d/www.conf
	sed -i "s/^listen.owner\([[:space:]]*\)=\([[:space:]]*\).*/listen.owner = $SSH_USERNAME/g" /etc/php/7.0/fpm/pool.d/www.conf
	sed -i "s/^listen.group\([[:space:]]*\)=\([[:space:]]*\).*/listen.group = $SSH_USERNAME/g" /etc/php/7.0/fpm/pool.d/www.conf
	sed -i "s/[;]*listen.mode\([[:space:]]*\)=\([[:space:]]*\).*/listen.mode = 0666/g" /etc/php/7.0/fpm/pool.d/www.conf

	echo "==> Installing Nginx 1.9"
	apt-get -y install nginx-full nginx
	# Nginx full 1.9
	sed -i "s/^user\([[:space:]]*\).*/user $SSH_USERNAME;/g" /etc/nginx/nginx.conf
	sed -i "s/[# ]*server_names_hash_bucket_size\([[:space:]]*\).*/server_names_hash_bucket_size 64;/g" /etc/nginx/nginx.conf

	echo "==> Installing other packages"
	apt-get -y install memcached
	# apt-get -y install redis-server sqlite3 postgresql
	apt-get -y install git nodejs rsync beanstalkd ssl-cert
	apt-get -y install blackfire-agent blackfire-php

	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer

	echo "==> Installing ZSH"
	apt-get -y install zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	# 切换默认SHELL
	sed -i.bak "s/\/bin\/bash/\/bin\/zsh/g" /etc/passwd

	echo "==> Installing MySQL 5.7"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $SSH_PASSWORD"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $SSH_PASSWORD"
	DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

	# Configure MySQL default charset to real utf8
	# sed  -i '/\[client\]/a default-character-set = utf8mb4' /etc/mysql/my.cnf
	# sed  -i '/\[mysqld\]/a character-set-client-handshake = FALSE' /etc/mysql/my.cnf
	# sed  -i '/\[mysqld\]/a character-set-server = utf8mb4' /etc/mysql/my.cnf
	# sed  -i '/\[mysqld\]/a collation-server = utf8mb4_unicode_ci' /etc/mysql/my.cnf
	sed -i "/\[client\]/a\default-character-set = utf8" /etc/mysql/my.cnf
	sed -i "/\[mysqld\]/a\collation-server = utf8_general_ci" /etc/mysql/my.cnf
	sed -i "/\[mysqld\]/a\character-set-server = utf8" /etc/mysql/my.cnf
	# sed -i "/\[mysql\]/a\default-character-set=utf8" /etc/mysql/my.cnf

	# Configure MySQL default engine to INNODB
	sed -i "/\[mysqld\]/a\default-storage-engine = INNODB" /etc/mysql/my.cnf

	# Allow remote connections to MySQL server
	sed -i "s/[# ]*bind-address\([[:space:]]*\)=\([[:space:]]*\).*/bind-address = 0.0.0.0/g" /etc/mysql/my.cnf
	mysql -uroot -p$SSH_PASSWORD -e "grant all on *.* to root@'%' identified by '$SSH_USERNAME'";
	mysql -uroot -p$SSH_PASSWORD -e "flush privileges";

	# Loads timezone tables
	mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=$SSH_PASSWORD --force mysql

	sed -i '$ a\'"default_password_lifetime = 0" /etc/mysql/my.cnf
fi
