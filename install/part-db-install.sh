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
  git \
  zip \
  ca-certificates \
  software-properties-common \
  apt-transport-https \
  lsb-release \
  wget \
  nano \
  php \
  libapache2-mod-php \
  php-opcache \
  php-curl \
  php-gd \
  php-mbstring \
  php-xml \
  php-bcmath \
  php-intl \
  php-zip \
  php-xsl \
  php-pgsql \
  nodejs \
  composer \
  postgresql
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=partdb
DB_USER=partdb
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
echo "Part-DB Credentials"
echo -e "Part-DB Database User: \e[32m$DB_USER\e[0m"
echo -e "Part-DB Database Password: \e[32m$DB_PASS\e[0m"
echo -e "Part-DB Database Name: \e[32m$DB_NAME\e[0m"
} >> ~/partdb.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Part-DB (Patience)"

git clone -q https://github.com/Part-DB/Part-DB-symfony.git /var/www/partdb
cd /var/www/partdb/
$STD git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
chown -R www-data:www-data /var/www/partdb
$STD composer install --no-dev -o --no-interaction
$STD yarn install
$STD yarn build
$STD sudo -u www-data php bin/console cache:clear

msg_ok "Installed Part-DB"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
