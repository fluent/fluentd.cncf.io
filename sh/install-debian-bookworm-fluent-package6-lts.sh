echo "=============================="
echo " fluent-package Installation Script "
echo "=============================="
echo "This script requires superuser access to install apt packages."
echo "You will be prompted for your password by sudo."

# clear any previous sudo permission
sudo -k

# run inside sudo
executed_distribution=$(cat /etc/os-release | grep "^ID=" | cut -d'=' -f2)
executed_release=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2)
sudo sh <<SCRIPT
  if [ ! "${executed_release}" = "bookworm" ]; then
    echo
    echo "[ERROR] Executed wrong installation script for debian bookworm on ${executed_distribution} ${executed_release}"
    echo
    exit 1
  fi
  # use apt-source package which contains keyring
  curl -o fluent-apt-source.deb https://fluentd.cdn.cncf.io/lts/6/debian/bookworm/pool/contrib/f/fluent-lts-apt-source/fluent-lts-apt-source_2026.4.29-1_all.deb
  apt install -y ./fluent-apt-source.deb
  rm -f ./fluent-apt-source.deb
  # update your sources
  apt update

  # install the toolbelt
  apt install -y fluent-package

SCRIPT

# message
if [ $? -eq 0 ]; then
  echo ""
  echo "Installation completed. Happy Logging!"
  echo ""
else
  echo ""
  echo "Installation incompleted. Check above messages."
  echo ""
fi
