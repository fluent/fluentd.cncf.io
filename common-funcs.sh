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
    ID=$(cat /etc/os-release | grep "^ID=" | cut -d'=' -f2)
    VERSION_ID=$(cat /etc/os-release | grep VERSION_ID | cut -d'=' -f2)
    DNF=dnf
    case $ID in
	*centos*)
	    sed -i -e 's,^mirrorlist=,#mirrorlist,' /etc/yum.repos.d/CentOS-Base.repo
	    sed -i -e 's,^#baseurl=http://mirror.centos.org/centos/\$releasever/,baseurl=http://ftp.iij.ad.jp/pub/linux/centos/7.9.2009/,' /etc/yum.repos.d/CentOS-Base.repo
	    cat /etc/yum.repos.d/CentOS-Base.repo
	    DNF=yum
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
