#!/bin/bash -eux

# Disable the release upgrader
echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

# 安装语言包
apt-get install -y language-pack-en-base
# 添加add-apt-repository命令
apt-get -y install software-properties-common

if [[ $LNMP  =~ true || $LNMP =~ 1 || $LNMP =~ yes ]]; then
    echo "==> Adding Apt Repository(Blackfire & PHP)"
	# Blackfire源
	wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
	echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list
	# PHP 7.0源
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
	LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php-qa
fi

echo "==> Updating list of repositories"
# apt-get update does not actually perform updates, it just downloads and indexes the list of packages
# if [[ $UPDATE_PROXY  =~ false || $UPDATE_PROXY =~ 0 || $UPDATE_PROXY =~ no ]]; then
# 	apt-get -y update
# else
	apt-get -y -o Acquire::http::proxy="http://192.168.0.2:8087/" update
# fi

echo "==> Installing software(Include Packages)"
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
	apt-get install -y php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-curl php7.0-intl php7.0-xsl php7.0-mbstring php7.0-zip php7.0-bcmath
	# 设置PHP时区
	sed -i.bak-timezone "s/;date.timezone =.*/date.timezone = PRC/" /etc/php/7.0/fpm/php.ini

	apt-get -y install memcached
	apt-get -y install nginx
	apt-get -y install git
	# apt-get -y install node.js perl ruby
	# blackfire
	apt-get install -y blackfire-agent

	echo "==> Installing ZSH"
	apt-get -y install zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	chsh -s /bin/zsh

#export MYSQL_PASS=vagrant
cat <<MYSQL5_PRESEED | debconf-set-selections
mysql-server-5.6 mysql-server/root_password password $SSH_PASSWORD
mysql-server-5.6 mysql-server/root_password_again password $SSH_PASSWORD
mysql-server-5.6 mysql-server/start_on_bootboolean true
MYSQL5_PRESEED
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'

	apt-get -y install mysql-server-5.6 mysql-client-5.6

	# MySQL远程连接
	sed -i.bak-bind "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

cat > ~/.my.cnf << EOF
[client]
user = root
password = $SSH_PASSWORD
EOF

	mysql -e "grant all on *.* to root@'%' identified by 'vagrant'";
	mysql -e "flush privileges";
	rm ~/.my.cnf

	# MySQL字符编码
	sed -i.bak-utf8 "/\[client\]/a\default-character-set=utf8" /etc/mysql/my.cnf
	sed -i "/\[mysqld\]/a\character-set-server=utf8" /etc/mysql/my.cnf
	sed -i "/\[mysql\]/a\default-character-set=utf8" /etc/mysql/my.cnf
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Performing dist-upgrade (all packages and kernel)"
    apt-get -y dist-upgrade --force-yes
    reboot
    sleep 60
fi
