#!/bin/bash -eux

SSH_PASSWORD=${SSH_PASSWORD:-vagrant}

if [[ $LNMP  =~ true || $LNMP =~ 1 || $LNMP =~ yes ]]; then
    echo "==> Adding Apt Repository(Blackfire & PHP)"
	# 添加add-apt-repository命令
	apt-get -y install software-properties-common
	# Blackfire源
	wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
	echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list
	# PHP 7.0源
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php-qa
fi

echo "==> Updating list of repositories"
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
apt-get -y install linux-headers-$(uname -r)
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
	apt-get install -y php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-curl php7.0-intl php7.0-mbstring
	apt-get install -y php7.0-zip php7.0-bcmath
	# 设置PHP时区
	sed -i.bak-timezone "s/;date.timezone =.*/date.timezone = PRC/" /etc/php/7.0/fpm/php.ini

	echo "==> Installing other packages"
	apt-get -y install memcached
	# apt-get -y install redis-server
	apt-get -y install nginx
	apt-get -y install git rsync beanstalkd blackfire-agent

	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer

	echo "==> Installing ZSH"
	apt-get -y install zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	# 切换默认SHELL
	sed -i.bak "s/\/bin\/bash/\/bin\/zsh/g" /etc/passwd

	echo "==> Installing MySQL 5.6"
	debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password password $SSH_PASSWORD"
	debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password_again password $SSH_PASSWORD"

	apt-get -y install mysql-server-5.6 mysql-client-5.6

	# MySQL远程连接
	sed -i.bak-bind "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
	mysql -uroot -p$SSH_PASSWORD -e "grant all on *.* to root@'%' identified by '$SSH_PASSWORD'";
	mysql -uroot -p$SSH_PASSWORD -e "flush privileges";

	# MySQL字符编码
	sed -i.bak-utf8 "/\[client\]/a\default-character-set=utf8" /etc/mysql/my.cnf
	sed -i "/\[mysqld\]/a\character-set-server=utf8" /etc/mysql/my.cnf
	sed -i "/\[mysql\]/a\default-character-set=utf8" /etc/mysql/my.cnf
fi
