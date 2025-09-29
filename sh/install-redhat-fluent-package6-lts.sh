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
  distribution=$(cat /etc/system-release-cpe | awk '{print substr($1, index($1, "o"))}' | cut -d: -f2)
  version=$(cat /etc/system-release-cpe | awk '{print substr($1, index($1, "o"))}' | cut -d: -f4)
  arch=$(rpm --eval %{_arch})
  curl --silent -o fluent-release.rpm https://fluentd.cdn.cncf.io/lts/6/redhat/${version}/${arch}/fluent-lts-release-2025.9.29-1.el${version}.noarch.rpm
  if [ -e /etc/yum.repos.d/fluent-package-lts.repo ]; then
    if ! rpm -qf /etc/yum.repos.d/fluent-package-lts.repo; then
      echo "Backup unmanaged .repo to fluent-package-lts.repo.rpmsave"
      mv /etc/yum.repos.d/fluent-package-lts.repo /etc/yum.repos.d/fluent-package-lts.repo.rpmsave
    fi
  fi
  yum install -y ./fluent-release.rpm
  rm -f ./fluent-release.rpm

  # update your sources
  yum check-update

  # install the toolbelt
  yes | yum install -y fluent-package

SCRIPT

# message
echo ""
echo "Installation completed. Happy Logging!"
echo ""
