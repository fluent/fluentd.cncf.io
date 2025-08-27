echo "=============================="
echo " fluent-package Installation Script "
echo "=============================="
echo "This script requires superuser access to install rpm packages."
echo "You will be prompted for your password by sudo."

# clear any previous sudo permission
sudo -k

# run inside sudo
sudo sh <<'SCRIPT'
  # add GPG key
  rpm --import https://fluentd.cdn.cncf.io/GPG-KEY-td-agent
  rpm --import https://fluentd.cdn.cncf.io/GPG-KEY-fluent-package

  # add fluent-package repository to yum
  cat >/etc/yum.repos.d/fluent-package-lts.repo <<'EOF';
[fluent-package-lts]
name=Fluentd Project
baseurl=https://fluentd.cdn.cncf.io/lts/5/redhat/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://fluentd.cdn.cncf.io/GPG-KEY-td-agent
       https://fluentd.cdn.cncf.io/GPG-KEY-fluent-package
EOF

  # update your sources
  yum check-update

  # install the toolbelt
  yes | yum install -y fluent-package

SCRIPT

# message
echo ""
echo "Installation completed. Happy Logging!"
echo ""
