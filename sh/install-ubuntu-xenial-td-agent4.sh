echo "=============================="
echo " td-agent Installation Script "
echo "=============================="
echo "This script requires superuser access to install apt packages."
echo "You will be prompted for your password by sudo."

# clear any previous sudo permission
sudo -k

# run inside sudo
sudo sh <<SCRIPT
  
    # Deprecated
    curl https://fluentd.cdn.cncf.io/GPG-KEY-td-agent | apt-key add -
    # add treasure data repository to apt
    echo "deb https://fluentd.cdn.cncf.io/4/ubuntu/xenial/ xenial contrib" > /etc/apt/sources.list.d/treasure-data.list
  
  # update your sources
  apt update

  # install the toolbelt
  apt install -y td-agent

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
