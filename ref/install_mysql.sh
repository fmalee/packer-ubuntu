#!/bin/bash
# install_mysql.sh
#-----------------------------------------
# A script of auto compile & install MySQL(5.7.6 and up) on Ubuntu14.x
# @Version 1.0.0.160118
# @Author cidens
# @Comment Ubuntu 14.04.3 LTS x86_64 下测试通过
#-------------------------------------------------
# 建议预先准备好boost的源码tar包(mysql5.7.6及以上版本必需),
# mysql的源码tar包和此脚本放在同一个文件夹下
# 注意：
# 1.此脚本不要放在_INSTALLDIR和_MYSQL_BASE的目录下，以免冲突
# 2.执行脚本前请清空MySQL使用的/data 目录
# 3.此脚本仅适用于MySQL5.7.6及以上版本，之前的版本从configMysql步骤开始部分命令不同
# 4.my.cnf中如果有"server_id="的设置，部署时会自动根据主机IP后三位替换。

# Define 
_WORKPATH=$(pwd)
_USER="mysql"
_GROUP="mysql"
_VERSION="5.7.10"
_INSTALLDIR="/usr/local/mysql-${_VERSION}"
_MYSQL_BASE="/usr/local/mysql"
_LOGPATH="${_WORKPATH}/mysql_install.log"
_TARNAME="mysql-${_VERSION}.tar.gz"
_CMAKEDIR="mysql-${_VERSION}"
_DOWNTAR_URL="http://mirrors.sohu.com/mysql/MySQL-5.7/${_TARNAME}"

_BOOST_TARNAME="boost_1_59_0.tar.gz"
_BOOST_DOWNTAR_URL="http://downloads.sourceforge.net/project/boost/boost/1.59.0/${_BOOST_TARNAME}"
_CNFFILE="my.cnf"
_ROOTPWD="root"
_ERRORFILE=${_WORKPATH}/"error.lock"

echoLog()
{ #写日志
echo "*** [$(date "+%Y-%m-%d %H:%M:%S")] ${1}"
}

checkContinue()
{ # 判断是否继续
if [ -s ${_ERRORFILE} ]; then
    #前一步未完成则退出
    echo "error exit.See ${_LOGPATH} for details."
    exit 2
fi
}

errorDo()
{ # 出错处理
echo -e "this is Installation error temporary file.\nif errors has been resolved, you can delete this file" >>${_ERRORFILE}
}

readINI()
{ # 读取配置文件
_INIFILE=$1; _SECTION=$2; _ITEM=$3
_readIni=`sudo awk -F '=' '/\['${_SECTION}'\]/{a=1}a==1&&$1~/'${_ITEM}'/{print $2;exit}' ${_INIFILE}`
echo "read from ${_INIFILE}:${_ITEM}=[${_readIni}]"
}

writeINI()
{ # 写入配置文件
_INIFILE=$1; _SECTION=$2; _ITEM=$3; _NEWVAL=$4
echo "write to ${_INIFILE}:${_ITEM}=${_NEWVAL}"
sudo sed -i "{/^\[${_SECTION}/b;/^\[/b;s/^${_ITEM}*=.*/${_ITEM}=${_NEWVAL}/g;}" ${_INIFILE}
}
showInfo()
{ #
echo "Please confirm the following settings.If wrong,MODIFY it first."
echo "---------------------------------"
echo "_USER=["${_USER}"]"
echo "_GROUP=["${_GROUP}"]"
echo "_VERSION=["${_VERSION}"]"
echo "_INSTALLDIR=["${_INSTALLDIR}"]"
echo "_MYSQL_BASE=["${_MYSQL_BASE}"]"
echo "_LOGPATH=["${_LOGPATH}"]"
echo "_TARNAME=["${_TARNAME}"]"
echo "_DOWNTAR_URL=["${_DOWNTAR_URL}"]"
echo "_BOOST_TARNAME=["${_BOOST_TARNAME}"]"
echo "_BOOST_DOWNTAR_URL=["${_BOOST_DOWNTAR_URL}"]"
echo "_CNFFILE=["${_CNFFILE}"]"
echo "----------------------------------"
echo "Install MySQL-"${_VERSION}" now ? Please input y"
_ISYES="n"
read -p "(Please input y , n):" _ISYES
case "$_ISYES" in
  [yY][eE][sS]|[yY])
    echo -e "\nNow start install MySQL-"${_VERSION}
    _ISYES="y"
    ;;
  *)
    echo -e "\nINPUT error, exit install now"
    _ISYES="n"
    errorDo
    return 1
    ;;
esac
}

installDependPackage()
{ # 安装依赖的包和工具,-y直接输入y
echoLog "Start check and install depend packges....."
echo "sudo apt-get install make cmake gcc g++ bison libncurses5-dev libaio1 -y"
sudo apt-get update
sudo apt-get install make cmake gcc g++ bison libncurses5-dev libaio1 -y
}

addUserGroup()
{ # 创建用户和组
echoLog "Create group:${_GROUP} if not exists ..."
sudo egrep "^${_GROUP}" /etc/group >& /dev/null
if [ $? -ne 0 ]; then
        echo "sudo groupadd ${_GROUP}"
        sudo groupadd ${_GROUP}
fi

echoLog "Create user:${_USER} if not exists ..."
sudo egrep "^${_USER}" /etc/passwd >& /dev/null
if [ $? -ne 0 ]; then
        echo "sudo useradd -g ${_GROUP} ${_USER} -s /usr/bin/false"
        sudo useradd -g ${_GROUP} ${_USER} -s /usr/bin/false
fi
}

createDir()
{ # 创建目录
echoLog "Create dir, MySQL will installed on ${_INSTALLDIR}"

sudo mkdir -p ${_INSTALLDIR}
if [ ! -d ${_MYSQL_BASE} ]; then
    echo "ln -s ${_INSTALLDIR} ${_MYSQL_BASE}"
    sudo ln -s ${_INSTALLDIR} ${_MYSQL_BASE}
fi

if [ -d /data ] && [ -d /log ];then
    echo "ln -s {/data,/log} ${_MYSQL_BASE}"
        sudo ln -s /data ${_MYSQL_BASE}
        sudo ln -s /log ${_MYSQL_BASE}
        sudo mkdir -p ${_MYSQL_BASE}/run
        sudo chown -R ${_USER}:${_GROUP} {/data,/log}
else
        sudo mkdir -p ${_MYSQL_BASE}/{data,log,run}
fi
sudo chown -R ${_USER}:${_GROUP} {${_MYSQL_BASE},${_MYSQL_BASE}/run,${_INSTALLDIR}}
}

checkAndDownloadFiles()
{ # 获取安装包
echoLog "Check if ${_TARNAME} exists....."
if [ -s ${_TARNAME} ]; then
        echo "$(pwd)/${_TARNAME} [found]"
else
    echo "$(pwd)/${_TARNAME} not found!!! download now....."
    sudo wget -c ${_DOWNTAR_URL}
fi
echo "tar -zxvf ${_TARNAME}"
sudo tar -zxvf ${_TARNAME}

echoLog "Check if ${_BOOST_TARNAME} exists....."
if [ -s ${_BOOST_TARNAME} ]; then
        echo "$(pwd)/${_BOOST_TARNAME} [found]"
else
    echo "$(pwd)/${_BOOST_TARNAME} not found!!! download now....."
    sudo wget -c ${_BOOST_DOWNTAR_URL}
fi
echo "tar -zxvf ${_BOOST_TARNAME}"
sudo tar -zxvf ${_BOOST_TARNAME}
}

doCmake()
{ # cmake
echoLog "Start cmake....."
cd ${_WORKPATH}/${_CMAKEDIR}
CFLAGS="-O3 -g -fno-exceptions -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing"
CXX=g++
CXXFLAGS="-O3 -g -fno-exceptions -fno-rtti -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing"

echo "CFLAGSR=["${CFLAGS}"]"
echo "CXX=["${CXX}"]"
echo "CXXFLAGS=["${CXXFLAGS}"]"
export CFLAGS CXX CXXFLAGS

CMAKE_PARA="\
-DCMAKE_INSTALL_PREFIX=${_MYSQL_BASE} \
-DSYSCONFDIR=${_MYSQL_BASE} \
-DMYSQL_DATADIR=${_MYSQL_BASE}/data \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_EXTRA_CHARSETS=all \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_USER=${_USER} \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=../boost_1_59_0"

# 注意：重新编译时，需要清除旧的对象文件和缓存信息
# sudo make clean
# rm -f CMakeCache.txt

echo "sudo cmake ${CMAKE_PARA}"
sudo cmake ${CMAKE_PARA}

if [ $? -eq 0 ];then
    echoLog "sudo make -j && make install"
    sudo make -j `cat /proc/cpuinfo | grep processor| wc -l` && sudo make install    
else
    echoLog "cmake error[$?], exit install now."
    errorDo
    return 2
fi

if [ $? -ne 0 ];then
    echoLog "make error[$?], exit install now."
    errorDo
    return 2
fi
echoLog "make success."
}

configMysql()
{ # config
echoLog "Start configMysql..... "
cd ${_WORKPATH}
if [ -s /etc/my.cnf ]; then
    echo "backup /etc/my.cnf"
    sudo mv /etc/my.cnf /etc/my.cnf.`date +%Y%m%d%H%M%S`.bak
fi
if [ -s ${_CNFFILE} ]; then
    echo "mysql user-defined config[${_CNFFILE}] is [found]"
    sudo cp ${_CNFFILE} /etc/my.cnf
else
    echo "cp ${_MYSQL_BASE}/support-files/my-default.cnf /etc/my.cnf"
    sudo cp ${_MYSQL_BASE}/support-files/my-default.cnf /etc/my.cnf
fi
# set server_id
_SERVER_ID=`ifconfig eth0 | grep -Po '(?<=\sinet\s)[^\s]*'|awk -F . '{print $NF}'`
if [ ${_SERVER_ID} -gt 0 ]; then
    readINI /etc/my.cnf mysqld server_id
    writeINI /etc/my.cnf mysqld server_id ${_SERVER_ID}
    echo "after set server_id. "
    readINI /etc/my.cnf mysqld server_id
fi
sudo chown ${_USER}:${_GROUP} /etc/my.cnf

# initMySQL
_INITPARAM="\
--initialize-insecure \
--user=${_USER} \
--basedir=${_MYSQL_BASE} \
--datadir=${_MYSQL_BASE}/data \
--explicit_defaults_for_timestamp"
cd ${_MYSQL_BASE}
echo "sudo bin/mysqld ${_INITPARAM}"
sudo bin/mysqld ${_INITPARAM}

if [ $? -ne 0 ];then 
    echoLog "execute mysqld error, exit install now."
    errorDo
    return 2
fi


echo "sudo bin/mysql_ssl_rsa_setup"
sudo bin/mysql_ssl_rsa_setup
if [ $? -ne 0 ];then
    echoLog "execute mysql_ssl_rsa_setup error, exit install now."
    errorDo
    return 2
fi
#sudo chown -R root .
sudo chown -R ${_USER} data

# 设置开机启动服务
sudo cp ${_MYSQL_BASE}/support-files/mysql.server /etc/init.d/
sudo chmod +x /etc/init.d/mysql.server
sudo update-rc.d -f mysql.server defaults
echoLog "config success."
}

getMysqlStat()
{ # 检查服务是否启动
_CMDCHECK=`sudo lsof -i:3306 &>/dev/null`
_Port=$?
_PIDCHECK=`ps aux|grep mysqld|grep -v grep`
_PID=$?
if [ ${_Port} -eq 0 -a ${_PID} -eq 0 ];then
    echo "MySQL is running..."
    return 0
else
    echo "MySQL is not running."
    return 2
fi
}

setRootPwd()
{ # set mysql root password
getMysqlStat 
if [ $? -ne 0 ]; then
    echo "can't connect to mysql server.can not set root password now. "
    errorDo
    return 2
fi

sudo ${_MYSQL_BASE}/bin/mysql -e \
"grant all privileges on *.* to root@'127.0.0.1' identified by \"$_ROOTPWD\" with grant option;"
sudo ${_MYSQL_BASE}/bin/mysql -e \
"grant all privileges on *.* to root@'localhost' identified by \"$_ROOTPWD\" with grant option;"
echo "set root password ok."
}

# main begin ------------
showInfo 2>&1 | tee -a ${_LOGPATH}
checkContinue
echo "----------------"
echo -e "Please input the root password of mysql:"
read -p "(Default password:[root]):" _ROOTPWD
if [ "${_ROOTPWD}" = "" ]; then
    _ROOTPWD="root"
fi
echo -e "\n------------------"
echo "MySQL root password:[${_ROOTPWD}]"
echo "------------------"
installDependPackage 2>&1 | tee -a ${_LOGPATH}
addUserGroup 2>&1 | tee -a ${_LOGPATH}
createDir 2>&1 | tee -a ${_LOGPATH}
checkAndDownloadFiles  2>&1 | tee -a ${_LOGPATH}
doCmake 2>&1 | tee -a ${_LOGPATH}
checkContinue
configMysql 2>&1 | tee -a ${_LOGPATH}
# 尝试启动服务
checkContinue
sudo ${_MYSQL_BASE}/bin/mysqld_safe \
--defaults-file=/etc/my.cnf \
--user=${_USER}  2>&1 >>${_LOGPATH} &
sleep 5s
setRootPwd 2>&1 | tee -a ${_LOGPATH}
checkContinue
echoLog "Finish install." 2>&1 | tee -a ${_LOGPATH}