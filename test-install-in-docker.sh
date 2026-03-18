#!/bin/bash

set -e

#
# Intended to be invoked from test-verify-repo.sh
#
# Usage:
#   test-install-in-docker.sh $USER 6
#   test-install-in-docker.sh $USER lts/6
#   test-install-in-docker.sh $USER exp/6
#   test-install-in-docker.sh $USER exp/lts/6
#

function setup_apt_user()
{
    apt update
    apt upgrade -y
    apt install -y sudo expect curl
    useradd -m -s /bin/bash $USER
    gpasswd -a $USER sudo
    echo "$USER ALL=NOPASSWD: ALL" > /etc/sudoers.d/$USER
    su - $USER
}

function setup_dnf_user()
{
    case $ID in
	*centos*)
	    sed -i -e 's,^mirrorlist=,#mirrorlist,' /etc/yum.repos.d/CentOS-Base.repo
	    sed -i -e 's,^#baseurl=http://mirror.centos.org/centos/\$releasever/,baseurl=http://ftp.iij.ad.jp/pub/linux/centos/7.9.2009/,' /etc/yum.repos.d/CentOS-Base.repo
	    cat /etc/yum.repos.d/CentOS-Base.repo
	    ;;
    esac
    $DNF update -y
    case $VERSION_ID in
	*2023*|*9\.*|*10\.*)
	    # curl-minimal should be used by default
	    $DNF install -y sudo expect shadow-utils passwd util-linux
	    ;;
	*)
	    $DNF install -y sudo expect curl shadow-utils passwd util-linux
	    ;;
    esac
    useradd -m -s /bin/bash -u 1000 $USER
    gpasswd -a $USER wheel
    echo "$USER ALL=NOPASSWD: ALL" > /etc/sudoers.d/$USER
    su - $USER
}

function check_installed_version()
{
    VERSION=$1
    case $VERSION in
	*$TARGET*)
	    echo "Succeeded to install $TARGET on $ID from $REPO"
	    ;;
	*)
	    echo "Failed to install $TARGET on $ID from $REPO"
	    exit 1
	    ;;
    esac
}

USER=$1
REPO=$2
TARGET=$3

DNF=dnf

ID=$(cat /etc/os-release | grep "^ID=" | cut -d'=' -f2)
case $ID in
    debian|ubuntu)
	export DEBIAN_FRONTEND=noninteractive
	CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2)
	case $CODENAME in
	    bullseye|bookworm|trixie|focal|jammy|noble)
		setup_apt_user
                export DEBIAN_FRONTEND=noninteractive
                echo -e 'Dpkg::Options {\n"--force-confnew";\n}' | tee /etc/apt/apt.conf.d/90force-confnew
                cat /etc/apt/apt.conf.d/90force-confnew
		case $REPO in
		    6)
			cat /host/sh/install-$ID-$CODENAME-fluent-package6.sh | sh
			;;
		    lts/5)
			cat /host/sh/install-$ID-$CODENAME-fluent-package5-lts.sh | sh
			;;
		    lts/6)
			cat /host/sh/install-$ID-$CODENAME-fluent-package6-lts.sh | sh
			;;
		    exp/5)
			set +e
			cat /host/sh/install-$ID-$CODENAME-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,'
			cat /host/sh/install-$ID-$CODENAME-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,' | sh
			set -e
			sudo sed -i -e 's,/5,/test/experimental/5,' /etc/apt/sources.list.d/fluent.sources
			sudo apt update
			sudo apt install -y fluent-package
			;;
		    exp/lts/5)
			set +e
			cat /host/sh/install-$ID-$CODENAME-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,'
			cat /host/sh/install-$ID-$CODENAME-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,' | sh
			set -e
			sudo sed -i -e 's,/lts/5,/test/experimental/lts/5,' /etc/apt/sources.list.d/fluent-lts.sources
			sudo apt update
			sudo apt install -y fluent-package
			;;
		    exp/6)
			set +e
			cat /host/sh/install-$ID-$CODENAME-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,'
			cat /host/sh/install-$ID-$CODENAME-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,' | sh
			set -e
			sudo sed -i -e 's,/6,/test/experimental/6,' /etc/apt/sources.list.d/fluent.sources
			sudo apt update
			sudo apt install -y fluent-package
			;;
		    exp/lts/6)
			set +e
			cat /host/sh/install-$ID-$CODENAME-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,'
			cat /host/sh/install-$ID-$CODENAME-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,' | sh
			set -e
			sudo sed -i -e 's,/lts/6,/test/experimental/lts/6,' /etc/apt/sources.list.d/fluent-lts.sources
			sudo apt update
			sudo apt install -y fluent-package
			;;
		esac
		sudo apt update
		sudo apt upgrade -y
		v=$(apt-cache show fluent-package | grep "^Version" | head -n 1 | cut -d':' -f 2)
		check_installed_version $v
		;;
	esac
	;;
    *centos*|*almalinux*|*rocky*)
	DNF=yum
	VERSION_ID=$(cat /etc/os-release | grep VERSION_ID | cut -d'=' -f2)
	setup_dnf_user
	case $REPO in
	    6)
		cat /host/sh/install-redhat-fluent-package6.sh | sh
		;;
	    lts/5)
		cat /host/sh/install-redhat-fluent-package5-lts.sh | sh
		;;
	    lts/6)
		cat /host/sh/install-redhat-fluent-package6-lts.sh | sh
		;;
	    exp/5)
		set +e
		cat /host/sh/install-redhat-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,'
		cat /host/sh/install-redhat-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,' | sh
		set -e
		sudo $DNF update -y
		sudo $DNF install -y fluent-package
		;;
	    exp/lts/5)
		set +e
		cat /host/sh/install-redhat-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,'
		cat /host/sh/install-redhat-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,' | sh
		set -e
		sudo $DNF update -y
		sudo $DNF install -y fluent-package
		;;
	    exp/6)
		set +e
		cat /host/sh/install-redhat-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,'
		cat /host/sh/install-redhat-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,' | sh
		set -e
		sudo sed -i -e 's,/6,/test/experimental/6,' /etc/yum.repos.d/fluent-package.repo
		sudo $DNF update -y
		sudo $DNF install -y fluent-package
		;;
	    exp/lts/6)
		set +e
		cat /host/sh/install-redhat-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,'
		cat /host/sh/install-redhat-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,' | sh
		set -e
		sudo sed -i -e 's,/lts/6,/test/experimental/lts/6,' /etc/yum.repos.d/fluent-package-lts.repo
		sudo $DNF update -y
		sudo $DNF install -y fluent-package
		;;
	esac
	$DNF update -y
	v=$($DNF info fluent-package | grep "^Version" | head -n 1 | cut -d':' -f 2)
	check_installed_version $v
	;;
    *amzn*)
	VERSION_ID=$(cat /etc/os-release | grep VERSION_ID | cut -d'=' -f2)
        DNF=yum
        case $VERSION_ID in
	    *2023*)
		setup_dnf_user
		case $REPO in
		    6)
			cat /host/sh/install-amazon2023-fluent-package6.sh | sh
			;;
		    lts/5)
			cat /host/sh/install-amazon2023-fluent-package5-lts.sh | sh
			;;
		    lts/6)
			cat /host/sh/install-amazon2023-fluent-package6-lts.sh | sh
			;;
		    exp/5)
			set +e
			cat /host/sh/install-amazon2023-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,'
			cat /host/sh/install-amazon2023-fluent-package5.sh | sed -e 's,/5,/test/experimental/5,' | sh
			set -e
			sudo $DNF update -y
			sudo $DNF install -y fluent-package
			;;
		    exp/lts/5)
			set +e
			cat /host/sh/install-amazon2023-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,'
			cat /host/sh/install-amazon2023-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,' | sh
			set -e
			sudo $DNF update -y
			sudo $DNF install -y fluent-package
			;;
		    exp/6)
			set +e
			cat /host/sh/install-amazon2023-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,'
			cat /host/sh/install-amazon2023-fluent-package6.sh | sed -e 's,/6,/test/experimental/6,' | sh
			set -e
			sudo sed -i -e 's,/6,/test/experimental/6,' /etc/yum.repos.d/fluent-package.repo
			sudo $DNF update -y
			sudo $DNF install -y fluent-package
			;;
		    exp/lts/6)
			set +e
			cat /host/sh/install-amazon2023-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,'
			cat /host/sh/install-amazon2023-fluent-package6-lts.sh | sed -e 's,/lts/6,/test/experimental/lts/6,' | sh
			set -e
			sudo sed -i -e 's,/lts/6,/test/experimental/lts/6,' /etc/yum.repos.d/fluent-package-lts.repo
			sudo $DNF update -y
			sudo $DNF install -y fluent-package
			;;
		esac
		;;
	    *2*)
		setup_dnf_user
		case $REPO in
		    lts/5)
			cat /host/sh/install-amazon2-fluent-package5-lts.sh | sh
			;;
		    exp/lts/5)
			set +e
			cat /host/sh/install-amazon2-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,'
			cat /host/sh/install-amazon2-fluent-package5-lts.sh | sed -e 's,/lts/5,/test/experimental/lts/5,' | sh
			set -e
			sudo $DNF update -y
			sudo $DNF install -y fluent-package
			;;
		esac
		;;
	esac
	$DNF update -y
	v=$($DNF info fluent-package | grep "^Version" | head -n 1 | cut -d':' -f 2)
	check_installed_version $v
	;;
esac
