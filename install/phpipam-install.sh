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
# RELEASE=$(curl -s https://api.github.com/repos/phpipam/phpipam/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
RELEASE="1.6.5"
wget -q "https://github.com/phpipam/phpipam/releases/download/v${RELEASE}/phpipam-v${RELEASE}.zip"
unzip -q "phpipam-v${RELEASE}.zip"
mv /opt/phpipam /var/www/

mysql -u root "${DB_NAME}" < /var/www/phpipam/db/SCHEMA.sql

cp /var/www/phpipam/config.dist.php /var/www/phpipam/config.php
sed -i "s/\(\$disable_installer = \).*/\1true;/" /var/www/phpipam/config.php
sed -i "s/\(\$db\['user'\] = \).*/\1'$DB_USER';/" /var/www/phpipam/config.php
sed -i "s/\(\$db\['pass'\] = \).*/\1'$DB_PASS';/" /var/www/phpipam/config.php
sed -i "s/\(\$db\['name'\] = \).*/\1'$DB_NAME';/" /var/www/phpipam/config.php

cat <<EOF >/etc/apache2/sites-available/phpipam.conf
<VirtualHost *:80>
    ServerName phpipam
    DocumentRoot /var/www/phpipam
    <Directory /var/www/phpipam>
        AllowOverride All
        Order Allow,Deny
        Allow from All
    </Directory>

    ErrorLog /var/log/apache2/phpipam_error.log
    CustomLog /var/log/apache2/phpipam_access.log combined
</VirtualHost>
EOF
$STD a2ensite phpipam
$STD a2enmod rewrite
rm /etc/apache2/sites-enabled/000-default.conf
service apache2 restart

echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed phpIPAM"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/phpipam-v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"