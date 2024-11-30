#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/bvdberg02/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/bvdberg02/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
           __          ________  ___    __  ___
    ____  / /_  ____  /  _/ __ \/   |  /  |/  /
   / __ \/ __ \/ __ \ / // /_/ / /| | / /|_/ / 
  / /_/ / / / / /_/ // // ____/ ___ |/ /  / /  
 / .___/_/ /_/ .___/___/_/   /_/  |_/_/  /_/   
/_/         /_/                                
                                   
EOF
}
header_info
echo -e "Loading..."
APP="phpIPAM"
var_disk="4"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
check_container_storage
check_container_resources
if [[ ! -d /var/www/phpipam ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

RELEASE=$(curl -s https://api.github.com/repos/phpipam/phpipam/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping Apache2"
  systemctl stop apache2
  msg_ok "Stopped Apache2"

  msg_info "Updating ${APP} to v${RELEASE}"
  mv /var/www/phpipam/ /opt/phpipam-backup
  wget -q "https://github.com/phpipam/phpipam/releases/download/v${RELEASE}/phpipam-v${RELEASE}.zip"
  unzip -q "phpipam-v${RELEASE}.zip"
  mv /opt/phpipam /var/www/
  cp /opt/phpipam-backup/config.php /var/www/phpipam
  msg_ok "Updated $APP to v${RELEASE}"

  msg_info "Starting Apache2"
  systemctl start apache2
  msg_ok "Started Apache2"

  msg_info "Cleaning up"

  msg_ok "Cleaned"

  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at v${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}${CL} \n"
