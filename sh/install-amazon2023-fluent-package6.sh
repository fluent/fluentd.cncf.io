echo "=============================="
echo " fluent-package Installation Script "
echo "=============================="
echo "This script requires superuser access to install rpm packages."
echo "You will be prompted for your password by sudo."

# clear any previous sudo permission
sudo -k

# run inside sudo
sudo sh <<'SCRIPT'

  # add fluent-release to access repository
  version=$(cat /etc/system-release-cpe | awk '{print substr($1, index($1, "o"))}' | cut -d: -f4)
  arch=$(rpm --eval %{_arch})
  curl -o fluent-release.rpm https://fluentd.cdn.cncf.io/6/amazon/${version}/${arch}/fluent-release-2025.9.29-1.amzn${version}.noarch.rpm
  if [ -e /etc/yum.repos.d/fluent-package.repo ]; then
    if ! rpm -qf /etc/yum.repos.d/fluent-package.repo; then
      echo "Backup unmanaged .repo to fluent-package.repo.rpmsave"
      mv /etc/yum.repos.d/fluent-package.repo /etc/yum.repos.d/fluent-package.repo.rpmsave
    fi
  fi
  yum install -y ./fluent-release.rpm
  rm -f ./fluent-release.rpm

  # update your sources
  yum check-update

  # install the toolbelt
  if rpm -q fluent-package; then
    yum update -y fluent-package
  else
    yum install -y fluent-package
  fi

SCRIPT

# message
echo ""
echo "Installation completed. Happy Logging!"
echo ""
