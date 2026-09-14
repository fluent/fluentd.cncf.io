#!/bin/bash

set -ex

#
# Intended to be invoked from test-guard-installation.sh
#
# Usage:
#   test-install-failure-in-docker.sh $USER /host/sh/install-debian-trixie-fluent-package6.sh
#

source /host/common-funcs.sh

USER=$1
SCRIPT=$2

ID=$(cat /etc/os-release | grep "^ID=" | cut -d'=' -f2)
case $ID in
    debian|ubuntu)
	export DEBIAN_FRONTEND=noninteractive
	setup_apt_user
        echo -e 'Dpkg::Options {\n"--force-confnew";\n}' | tee /etc/apt/apt.conf.d/90force-confnew
        cat /etc/apt/apt.conf.d/90force-confnew
	sudo apt update
        sudo apt upgrade -V -y
        ${SCRIPT}
        if [ $? -ne 0 ]; then
            exit 1
        else
            exit 0
        fi
	;;
esac
