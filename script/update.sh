#!/bin/bash -eux

# Disable the release upgrader
echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

echo "==> Updating list of repositories"
if [[ $UPDATE_PROXY == false || $UPDATE_PROXY == 0 || $UPDATE_PROXY == no ]]; then
	apt-get -y update
else
	echo "==> Updating with proxy"
	apt-get -y -o Acquire::http::proxy="$UPDATE_PROXY" update
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Performing dist-upgrade (all packages and kernel)"
    apt-get -y dist-upgrade --force-yes
    reboot
    sleep 60
fi