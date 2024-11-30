#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/bvdberg02/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  mariadb-server \
  apache2 \
  php \
  php-{pdo,mysql,sockets,gmp,ldap,simplexml,json,cli,mbstring,pear,gd,curl}
msg_ok "Installed Dependencies"

msg_info "Setting up MariaDB"
DB_NAME=phpipam
DB_USER=phpipam
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "phpIPAM-Credentials"
    echo "phpIPAM Database User: $DB_USER"
    echo "phpIPAM Database Password: $DB_PASS"
    echo "phpIPAM Database Name: $DB_NAME"
} >> ~/phpipam.creds
msg_ok "Set up MariaDB"

msg_info "Installing phpIPAM"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/phpipam/phpipam/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/phpipam/phpipam/releases/download/v${RELEASE}/listmonk_${RELEASE}_linux_amd64.tar.gz"

echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed phpIPAM"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/listmonk_${RELEASE}_linux_amd64.tar.gz"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"