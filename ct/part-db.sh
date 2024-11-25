#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/bvdberg02/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/bvdberg02/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____             __        ____  ____ 
   / __ \____ ______/ /_      / __ \/ __ )
  / /_/ / __ `/ ___/ __/_____/ / / / __  |
 / ____/ /_/ / /  / /_/_____/ /_/ / /_/ / 
/_/    \__,_/_/   \__/     /_____/_____/  
                                          
EOF
}
header_info
echo -e "Loading..."
APP="Part-DB"
var_disk="4"
var_cpu="2"
var_ram="1024"
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
if [[ ! -f /etc/systemd/system/netbox.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

RELEASE=$(curl -s https://api.github.com/repos/netbox-community/netbox/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

  msg_info "Stopping ${APP}"
  systemctl stop netbox netbox-rq
  msg_ok "Stopped ${APP}"

  msg_info "Updating $APP to v${RELEASE}"
  mv /opt/netbox/ /opt/netbox-backup
  cd /opt
  wget -q "https://github.com/netbox-community/netbox/archive/refs/tags/v${RELEASE}.zip"
  unzip -q "v${RELEASE}.zip"
  mv /opt/netbox-${RELEASE}/ /opt/netbox/
  
  cp -r /opt/netbox-backup/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
  cp -r /opt/netbox-backup/netbox/media/ /opt/netbox/netbox/
  cp -r /opt/netbox-backup/netbox/scripts /opt/netbox/netbox/
  cp -r /opt/netbox-backup/netbox/reports /opt/netbox/netbox/
  cp -r /opt/netbox-backup/gunicorn.py /opt/netbox/

  if [ -f /opt/netbox-backup/local_requirements.txt ]; then
    cp -r /opt/netbox-backup/local_requirements.txt /opt/netbox/
  fi

  if [ -f /opt/netbox-backup/netbox/netbox/ldap_config.py ]; then
    cp -r /opt/netbox-backup/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/
  fi
  
  /opt/netbox/upgrade.sh &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated $APP to v${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start netbox netbox-rq
  msg_ok "Started ${APP}"

  msg_info "Cleaning up"
  rm -r "/opt/v${RELEASE}.zip"
  rm -r /opt/netbox-backup
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
