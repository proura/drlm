
function get_client_os () {

  local DISTRO_LIST="rhel fedora centos debian ubuntu arch gentoo"

  if [ -f /etc/os-release ]; then
    source <(grep -E "ID|VERSION_ID|ID_LIKE" /etc/os-release)

    echo "DISTRO=$ID"
    echo "RELEASE=$VERSION_ID"
    echo "CLI_VERSION=${VERSION_ID%%.*}"
    echo "ARCH=$(uname -m)"
    if [[ $DISTRO_LIST =~ $ID ]]; then echo "DISTRO_LIKE=$ID";
    elif [[ $ID_LIKE =~ rhel || $ID == ol ]]; then echo "DISTRO_LIKE=rhel";
    elif [[ $ID_LIKE =~ fedora ]]; then echo "DISTRO_LIKE=fedora";
    elif [[ $ID_LIKE =~ centos ]]; then echo "DISTRO_LIKE=centos";
    elif [[ $ID_LIKE =~ debian ]]; then echo "DISTRO_LIKE=debian";
    elif [[ $ID_LIKE =~ ubuntu ]]; then echo "DISTRO_LIKE=ubuntu";
    elif [[ $ID_LIKE =~ suse || $ID == sled || $ID == sles || $ID == sles_sap ]]; then echo "DISTRO_LIKE=suse";
    elif [[ $ID_LIKE =~ arch ]]; then echo "DISTRO_LIKE=arch";
    elif [[ $ID_LIKE =~ gentoo ]]; then echo "DISTRO_LIKE=gentoo";
    else echo "DISTRO_LIKE=unknown";
    fi
  else
    echo "DISTRO=old"
  fi

}

function ssh_get_client_os () {
  local USER=$1
  local CLI_NAME=$2
  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "$(declare -f get_client_os); get_client_os" | tr -d '\r' | tr -d '\$'
}

function get_distro () {
  if [ -f /etc/dpkg/origins/ubuntu ]; then echo ubuntu;
  elif [ -f /etc/debian_version ] && [ ! -f /etc/dpkg/origins/ubuntu ]; then echo debian;
  elif [ -f /etc/redhat-release ] && [ ! -f /etc/centos-release ] && [ ! -f /etc/rocky-release ] && [ ! -f /etc/almalinux-release ] && [ ! -f /etc/oracle-release ] && [ ! -f /etc/fedora-release ]; then echo rhel;
  elif [ -f /etc/fedora-release ] && [ -f /etc/redhat-release ]; then  echo fedora;
  elif [ -f /etc/rocky-release ] && [ -f /etc/redhat-release ]; then  echo rocky;
  elif [ -f /etc/almalinux-release ] && [ -f /etc/redhat-release ]; then  echo alma;
  elif [ -f /etc/oracle-release ] && [ -f /etc/redhat-release ]; then  echo ol;
  elif [ -f /etc/centos-release ] && [ -f /etc/redhat-release ]; then  echo centos;
  elif [ -f /etc/SuSE-release ] || [ -f /etc/SUSE-brand ]; then echo suse; 
  fi
}

function ssh_get_distro () {
  local USER=$1
  local CLI_NAME=$2
  echo $(ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -f get_distro); get_distro"  2> /dev/null) | tr -dc '[:alnum:][:punct:]'
}

function get_release () {
  if [ -f /etc/dpkg/origins/ubuntu ]; then grep "^VERSION_ID=" /etc/os-release | cut -d\" -f2; 
  elif [ -f /etc/debian_version ] && [ ! -f /etc/dpkg/origins/ubuntu ]; then cat /etc/debian_version;
  elif [ -f /etc/redhat-release ] && [ ! -f /etc/centos-release ] && [ ! -f /etc/rocky-release ] && [ ! -f /etc/almalinux-release ] && [ ! -f /etc/oracle-release ] && [ ! -f /etc/fedora-release ]; then cat /etc/redhat-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/fedora-release ] && [ -f /etc/redhat-release ]; then cat /etc/fedora-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/rocky-release ] && [ -f /etc/redhat-release ]; then cat /etc/rocky-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/almalinux-release ] && [ -f /etc/redhat-release ]; then cat /etc/almalinux-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/oracle-release ] && [ -f /etc/redhat-release ]; then cat /etc/oracle-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/centos-release ] && [ -f /etc/redhat-release ]; then cat /etc/centos-release | awk -F"release" '{print $2}' | awk '{print $1}';
  elif [ -f /etc/SuSE-release ]; then grep VERSION /etc/SuSE-release | awk '{print $3}';
  elif [ -f /etc/SUSE-brand ]; then grep VERSION /etc/SUSE-brand | awk '{print $3}';
  fi
}

function get_arch () {
  local USER=$1
  local CLI_NAME=$2
  ARCH=$(echo $(ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "arch 2> /dev/null"  2> /dev/null) | tr -dc '[:alnum:][:punct:]')
  if [ "$ARCH" == "" ]; then echo noarch; else echo $ARCH ; fi
}

function ssh_get_release () {
  local USER=$1
  local CLI_NAME=$2
  echo $(ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -f get_release); get_release 2> /dev/null"  2> /dev/null) | tr -dc '[:alnum:][:punct:]'
}

function ssh_get_rear_version () {
  local CLI_NAME=$1
  local REAR_VERSION="$(ssh $SSH_OPTS -p $SSH_PORT $DRLM_USER@$CLI_NAME "/usr/sbin/rear -V 2> /dev/null"  2> /dev/null)"
  REAR_VERSION="$(echo $REAR_VERSION | tr -dc '[:alnum:][:punct:]' | sed 's/Relax-and-Recover//')"
  echo "$REAR_VERSION"
}

function check_apt () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO apt-cache search netcat|grep -w netcat &>/dev/null)" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function check_yum () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO yum search netcat| grep -w netcat &> /dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function check_zypper () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO zypper se netcat| grep -w netcat &> /dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function check_pacman() {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "($SUDO pacman -Ss netcat | grep -w netcat &>/dev/null)" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function check_emerge() {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "($SUDO emerge --search netcat | grep -w netcat &>/dev/null)" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_dependencies_apt () {
  local USER=$1
  local CLI_NAME=$2
  local REAR_DEPENDENCIES="$3"
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO apt-get update &> /dev/null; $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y install ${REAR_DEPENDENCIES[@]} &> /dev/null)" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_dependencies_yum () {
  local USER=$1
  local CLI_NAME=$2
  local REAR_DEP_REDHAT="$3"
  local SUDO=$4
  if [ -n "$REAR_DEP_REDHAT" ]; then
    ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO yum -y install $REAR_DEP_REDHAT &>/dev/null )" &> /dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi
  fi
}

function install_dependencies_zypper () {
  local USER=$1
  local CLI_NAME=$2
  local REAR_DEP_SUSE="$3"
  local SUDO=$4
  if [ -n "$REAR_DEP_SUSE" ]; then
    ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO zypper --no-gpg-checks in -y $REAR_DEP_SUSE &>/dev/null )" &> /dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi
  fi
}

function install_dependencies_pacman() {
  local USER=$1
  local CLI_NAME=$2
  local DEPENDENCIES="$3"
  local SUDO=$4

  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "$( $SUDO pacman -Syu --noconfirm ${DEPENDENCIES[@]} &> /dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_dependencies_emerge() {
  local USER=$1
  local CLI_NAME=$2
  local DEPENDENCIES="$3"
  local SUDO=$4

  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "$( $SUDO emerge --sync && $SUDO emerge --quiet --ask=n ${DEPENDENCIES[@]} &> /dev/null )" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_yum () {
  $SUDO yum -y remove rear &> /dev/null
  $SUDO wget --no-check-certificate -P /tmp -O /tmp/rear.rpm $URL_REAR &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Error Downloading rear package"
  else
      $SUDO yum --nogpgcheck -y install /tmp/rear.rpm &> /dev/null
      if [ $? -ne 0 ]; then
          echo "Error Installing ReaR package"
      fi
  fi
}

function install_rear_yum_repo () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO yum -y remove rear; $SUDO yum -y install rear &>/dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_install_rear_yum () {
  local USER=$1
  local CLI_NAME=$2
  local URL_REAR=$3
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO URL_REAR; declare -f install_rear_yum); install_rear_yum" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_dpkg () {
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y remove rear &> /dev/null
  $SUDO wget --no-check-certificate -P /tmp -O /tmp/rear.deb $URL_REAR &> /dev/null
  if [ $? -ne 0 ]; then
    return 1
  else
    $SUDO /usr/bin/dpkg --force-confold --install /tmp/rear.deb &> /dev/null
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi
  return 0
}

function install_rear_deb_repo () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y remove rear; $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y install rear &>/dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_install_rear_dpkg () {
  local USER=$1
  local CLI_NAME=$2
  local URL_REAR=$3
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO URL_REAR; declare -f install_rear_dpkg); install_rear_dpkg" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_zypper_repo () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO zypper rm -y rear; $SUDO zypper in -y rear  &>/dev/null )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_zypper () {
  $SUDO zypper rm -y rear &> /dev/null
  $SUDO wget --no-check-certificate -P /tmp -O /tmp/rear.rpm $URL_REAR &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Error Downloading rear package"
  else
    $SUDO /usr/bin/zypper --no-gpg-checks in -y /tmp/rear.rpm &> /dev/null
    if [ $? -ne 0 ]; then
      echo "Error Installing ReaR package"
    fi
  fi
}

function ssh_install_rear_zypper () {
  local USER=$1
  local CLI_NAME=$2
  local URL_REAR=$3
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO URL_REAR; declare -f install_rear_zypper); install_rear_zypper" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_pacman() {
  $SUDO pacman -Rns --noconfirm rear &>/dev/null
  $SUDO wget --no-check-certificate -P /tmp -O /tmp/rear.pkg.tar.zst "$URL_REAR" &>/dev/null
  if [ $? -ne 0 ]; then
    return 1
  else
    $SUDO pacman -U --noconfirm /tmp/rear.pkg.tar.zst &>/dev/null
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi
  return 0
}

function install_rear_pacman_repo() {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "( $SUDO pacman -Rns --noconfirm rear; $SUDO pacman -Syu --noconfirm rear &>/dev/null )" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_install_rear_pacman() {
  local USER=$1
  local CLI_NAME=$2
  local URL_REAR=$3
  local SUDO=$4

  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "$(declare -p SUDO URL_REAR; declare -f install_rear_pacman); install_rear_pacman" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function install_rear_emerge() {
  $SUDO emerge --unmerge rear &>/dev/null
  $SUDO wget --no-check-certificate -P /tmp -O /tmp/rear.tbz2 "$URL_REAR" &>/dev/null
  if [ $? -ne 0 ]; then
    return 1
  else
    $SUDO emerge /tmp/rear.tbz2 &>/dev/null
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi
  return 0
}

function install_rear_emerge_repo() {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3

  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "( $SUDO emerge --unmerge rear; $SUDO emerge --quiet rear &>/dev/null )" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_install_rear_emerge() {
  local USER=$1
  local CLI_NAME=$2
  local URL_REAR=$3
  local SUDO=$4

  ssh $SSH_OPTS -p "$SSH_PORT" "$USER@$CLI_NAME" "$(declare -p SUDO URL_REAR; declare -f install_rear_emerge); install_rear_emerge" &>/dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_keygen () {
  ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P "" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function send_drlm_managed () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "( printf '%s\n%s\n%s\n%s\n' "DRLM_MANAGED=y" "DRLM_SERVER=$(hostname -s)" "DRLM_ID=$CLI_NAME" 'DRLM_REST_OPTS=\"$REST_OPTS_RESCUE\"' | ${SUDO} tee /etc/rear/local.conf >/dev/null && ${SUDO} chmod 644 /etc/rear/local.conf )" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function send_drlm_token () {
  local USER="$1"
  local CLI_NAME="$2"
  local SUDO="$3"

  if  [ ! -f $CONFIG_DIR/clients/${CLI_NAME}.token ]; then
    generate_client_token "$CLI_NAME"
  fi
  
  local TOKEN="$(/bin/cat $CONFIG_DIR/clients/${CLI_NAME}.token)"

  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "( echo '$TOKEN' | ${SUDO} tee /etc/rear/drlm.token >/dev/null && ${SUDO} chmod 600 /etc/rear/drlm.token )" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function send_drlm_stunnel_cfg () {
  local USER="$1"
  local CLI_NAME="$2"
  local SUDO="$3"

  
local STUNNEL_CFG=$(/bin/cat <<EOF
client = yes
verify = 1
CApath = /etc/rear/cert
verifyPeer = yes
options = NO_SSLv3
sslVersionMin = TLSv1.2
sslVersionMax = TLSv1.3
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
debug = 0
foreground = yes
connect = $(hostname -s):874
TIMEOUTclose = 1
EOF
)

  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "( ${SUDO} mkdir -vp /etc/rear/stunnel && echo '$STUNNEL_CFG' | ${SUDO} tee /etc/rear/stunnel/drlm.conf >/dev/null && ${SUDO} chmod 600 /etc/rear/stunnel/drlm.conf )" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function make_ssl_capath () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "( if [ ! -d /etc/rear/cert ]; then ${SUDO} mkdir -p /etc/rear/cert && ${SUDO} chmod 755 /etc/rear/cert; fi )" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function send_ssl_cert () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  local CERT=$(cat /etc/drlm/cert/drlm.crt)
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "$(declare -p CERT); ( echo \"$CERT\" | ${SUDO} tee /etc/rear/cert/$(hostname -s).crt >/dev/null \
  && ${SUDO} chmod 644 /etc/rear/cert/$(hostname -s).crt \
  && ${SUDO} ln -sf /etc/rear/cert/$(hostname -s).crt /etc/rear/cert/\`${SUDO} openssl x509 -hash -noout -in /etc/rear/cert/$(hostname -s).crt\`.0 )" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function send_drlm_hostname () {
  #make sure servername and fqdn are different
  if [ "$SRV_NAME" == "$SRV_NAME_FQDN" ]; then
    SRV_NAME_FQDN=""
  fi

  if [ -n "$SRV_IP" ] && [ -n "$SRV_NAME" ]; then
    HOSTS_LINE_NUM=0
    insert_host_line="true"

    #read each line of /etc/hosts
    while read line; do 
      HOSTS_LINE_NUM=$((HOSTS_LINE_NUM+1))
      #if line is not commented
      if [ -n "$(echo "$line" | grep -v "^#")" ]; then
        #get number of line elements
        line_num_elements="$(echo "$line" | wc -w)"

        #Control var to increment if server ip, name or fqdn found in each line
        found="0"

        #for each line element
        for (( j=1; j<=$line_num_elements; j++ )); do
          line_cur_element="$(echo $line | awk -v var=$j '{print $var}')"
          if [ "$line_cur_element" == "$SRV_IP" ]; then
            found=$((found+1))
          elif [ "$line_cur_element" == "$SRV_NAME" ]; then
            found=$((found+1))
          elif [ -n "$SRV_NAME_FQDN" ] && [ "$line_cur_element" == "$SRV_NAME_FQDN" ]; then
            found=$((found+1))
          fi
        done

        # if have fqdn and found 3 matches in a line, nothing to do and stop
        if [ -n "$SRV_NAME_FQDN" ] && [ "$found" == "3" ]; then
          insert_host_line="false"
          break
        # if don't have fqdn and found 2 matches in a line, nothing to do and stop
        elif [ -z "$SRV_NAME_FQDN" ] && [ "$found" == "2" ]; then
          insert_host_line="false"
          break
        # else if found something comment
        elif [ "$found" -gt "0" ]; then
          $SUDO sed "$HOSTS_LINE_NUM {s/^/#/}" -i /etc/hosts
        fi
      fi

    done</etc/hosts

    if [ "$insert_host_line" == "true" ]; then
      if [ -n "$SRV_NAME_FQDN" ]; then
        printf '%s\t%s %s\n' "$SRV_IP" "$SRV_NAME" "$SRV_NAME_FQDN" | $SUDO tee --append /etc/hosts >/dev/null
      else
        printf '%s\t%s\n' "$SRV_IP" "$SRV_NAME" | $SUDO tee --append /etc/hosts >/dev/null
      fi
    fi

  fi
}

function ssh_send_drlm_hostname () {
  local USER=$1
  local CLI_NAME=$2
  local SRV_IP=$3
  local SUDO=$4
  local SRV_NAME=$(hostname -s)
  local SRV_NAME_FQDN=$(hostname -f)
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "$(declare -p SRV_NAME SRV_NAME_FQDN SRV_IP SUDO; declare -f send_drlm_hostname); send_drlm_hostname" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function ssh_check_shell () {
  local USER=$1
  local CLI_NAME=$2
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "getent passwd $USER | cut -d: -f7 | grep -w /bin/bash" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function create_drlm_var () {
  $SUDO mkdir -p /var/lib/drlm/scripts
  # Check if client it's a DRLM server. If true, don't modify permissions 
  # because will broke functionality.
  if [ ! -x /usr/sbin/drlm -a ! -f /var/lib/drlm/drlm.sqlite ]; then
    $SUDO chown -R drlm:drlm /var/lib/drlm
    $SUDO chmod -R 700 /var/lib/drlm
  fi
}

function ssh_create_drlm_var () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} "$(declare -p SUDO; declare -f create_drlm_var); create_drlm_var" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function create_drlm_user () {
  local USER=$1
  local CLI_NAME=$2
  local DRLM_USER=$3
  local SUDO=$4
  PASS=$(echo -n changeme | openssl passwd -1 -stdin)
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$SUDO /usr/sbin/useradd -d /home/$DRLM_USER -c 'DRLM User Agent' -m -s /bin/bash -p '$PASS' $DRLM_USER" &> /dev/null
  if [ $? -eq 0 ];then return 0; else return 1; fi
}

function delete_drlm_user () {
  local USER=$1
  local CLI_NAME=$2
  local DRLM_USER=$3
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$SUDO /usr/sbin/userdel -f -r $DRLM_USER" &> /dev/null
  if [ $? -eq 0 ];then return 0; 
  else
    sleep 0.5
    ssh $SSH_OPTS -p $SSH_PORT ${USER}@${CLI_NAME} ${SUDO} id ${DRLM_USER} &> /dev/null
    if [ $? -eq 0 ]; then return 1; else return 0; fi
  fi
}

function disable_drlm_user_login () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "( $SUDO chage -I -1 -m 0 -M 99999 -E -1 $DRLM_USER; $SUDO passwd -l $DRLM_USER )" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function remove_authorized_keys () {
  sed -i /$AUTH_KEY/d $HOME/.ssh/authorized_keys
}

function ssh_remove_authorized_keys () {
  local USER=$1
  local CLI_NAME=$2
  local AUTH_KEY=$(cat /root/.ssh/id_rsa.pub|awk '{print $3}')
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p AUTH_KEY ; declare -f remove_authorized_keys); remove_authorized_keys" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function start_services () {
  for service in ${SERVICES[@]}; do
    if [ "$(ps -p 1 -o comm=)" == "systemd" ]; then
      $SUDO systemctl start $service.service
      $SUDO systemctl enable $service.service
    else
      if [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "ubuntu" ]; then
        $SUDO /usr/sbin/service $service start
        $SUDO /usr/sbin/update-rc.d $service enable
      else
        $SUDO /sbin/service $service start
        $SUDO /sbin/chkconfig $service on
      fi
    fi
  done
}

function ssh_start_services () {
  local USER=$1
  local CLI_NAME=$2
  local SERVICES="$3"
  local DISTRO=$4
  local SUDO=$5
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SERVICES DISTRO SUDO; declare -f start_services); start_services" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function config_sudo () {
  export PATH="$PATH:/sbin:/usr/sbin"

  set -o noglob
  if [ -z "$SUDO" ]; then 
    for sudo_element in "${SUDO_CMDS_DRLM[@]}"; do
      commands="$(echo "$sudo_element" | awk '{print $1}')"
      args=$(echo $sudo_element | awk '{$1=""; print $0}')
      neg=$(echo $commands | cut -c1)
      if [ "$neg" == "!" ]; then
        commands=$(echo $commands | awk -F'!' '{print $2}')
      else
        neg=''
      fi
      commands=$(which $commands --skip-alias)
      if [ -n "$commands" ]; then
        SUDO_COMMANDS+=( , $neg$commands $args )
      fi
    done
  else 
    for sudo_element in "${SUDO_CMDS_DRLM[@]}"; do
      commands="$(echo "$sudo_element" | awk '{print $1}')"
      args=$(echo $sudo_element | awk '{$1=""; print $0}')
      neg=$(echo $commands | cut -c1)
      if [ "$neg" == "!" ]; then
        commands=$(echo $commands | awk -F'!' '{print $2}')
      else
        neg=''
      fi
      commands=$($SUDO "PATH=$PATH" which $commands --skip-alias)
      if [ -n "$commands" ]; then
        SUDO_COMMANDS+=( , $neg$commands $args )
      fi
    done
  fi

  for sudo_script in "${SUDO_DRLM_SCRIPTS[@]}"; do
    SUDO_COMMANDS+=( , "$sudo_script" )
  done

  if [ ! -d /etc/sudoers.d/ ]; then
    $SUDO mkdir /etc/sudoers.d
    $SUDO chmod 755 /etc/sudoers.d
    $SUDO sh -c "echo '#includedir /etc/sudoers.d' >> /etc/sudoers"
  fi

  $SUDO cat > /tmp/etc_sudoers.d_drlm.sudo << EOF
  Cmnd_Alias DRLM = /usr/sbin/rear ${SUDO_COMMANDS[@]}
  $DRLM_USER    ALL=(root)      NOPASSWD: DRLM
EOF
  set +o noglob

  if [ -d /etc/sudoers.d/ ]; then
    $SUDO chmod 440 /tmp/etc_sudoers.d_drlm.sudo
    $SUDO chown root:root /tmp/etc_sudoers.d_drlm.sudo
    $SUDO cp -p /tmp/etc_sudoers.d_drlm.sudo /etc/sudoers.d/drlm
    $SUDO rm -f /tmp/etc_sudoers.d_drlm.sudo
    if [ $? -eq 0 ]; then return 0; else return 1;fi
  else
    return 1
  fi
}

function ssh_config_sudo () {
  local USER=$1
  local CLI_NAME=$2
  local DRLM_USER=$3
  local SUDO=$4
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p DRLM_USER SUDO_CMDS_DRLM SUDO_DRLM_SCRIPTS SUDO ; declare -f config_sudo); config_sudo" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function copy_ssh_id () {
  local USER=$1
  local CLI_NAME=$2
  local DRLM_USER=$3
  local SUDO=$4

  PUBKEY=$(</root/.ssh/id_rsa.pub)

  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "DRLM_USER_HOME_DIR=\"\$(getent passwd \"$DRLM_USER\" | cut -d: -f6)\" ;
      DRLM_USER_GROUP=\"\$(id -gn $DRLM_USER)\" ;
      if [ ! -d \"\$DRLM_USER_HOME_DIR/.ssh\" ]; then
          $SUDO mkdir \"\$DRLM_USER_HOME_DIR/.ssh\" ;
          $SUDO chown $DRLM_USER:\$DRLM_USER_GROUP \$DRLM_USER_HOME_DIR/.ssh ;
          $SUDO chmod 700 \$DRLM_USER_HOME_DIR/.ssh ;
      fi ;
      $SUDO cat \$DRLM_USER_HOME_DIR/.ssh/authorized_keys >> /tmp/authorized_keys ;
      $SUDO echo '$PUBKEY' >> /tmp/authorized_keys ;
      $SUDO mv /tmp/authorized_keys \$DRLM_USER_HOME_DIR/.ssh/authorized_keys ;
      $SUDO chown $DRLM_USER:\$DRLM_USER_GROUP \$DRLM_USER_HOME_DIR/.ssh/authorized_keys ;
      $SUDO chmod 600 \$DRLM_USER_HOME_DIR/.ssh/authorized_keys ;" &> /dev/null
}

function config_public_keys () {
  # Generate key and public key if does not exists
  $SUDO [ ! -f /root/.ssh/id_rsa ] && $SUDO /usr/bin/ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa <<<y &> /dev/null
  
  # Add drlm server to known_host if does not exists
  $SUDO /usr/bin/ssh-keygen -R $DRLM_SERVER &> /dev/null  

  # FIXME: Is better to add the hosts hashed but -H parameter does not work on centos 8
  # $SUDO /usr/bin/ssh-keyscan -H $DRLM_SERVER 2>/dev/null | $SUDO tee --append /root/.ssh/known_hosts >/dev/null
  $SUDO /usr/bin/ssh-keyscan $DRLM_SERVER 2>/dev/null | $SUDO tee --append /root/.ssh/known_hosts >/dev/null

  if [ -n "$DRLM_SERVER_IP" ]; then
    $SUDO /usr/bin/ssh-keyscan $DRLM_SERVER_IP 2>/dev/null | $SUDO tee --append /root/.ssh/known_hosts >/dev/null
  fi

  # return the public key to add and authorize the client in drlm server  
  $SUDO cat /root/.ssh/id_rsa.pub
}

function ssh_config_public_keys () {
  local USER=$1
  local CLI_NAME=$2
  local DRLM_SERVER_IP=$3
  local SUDO=$4
  local DRLM_SERVER="$(hostname -s)"
  
  echo $(ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO DRLM_SERVER DRLM_SERVER_IP ; declare -f config_public_keys); config_public_keys")
}

function sync_client_scripts () {
  local CLI_NAME=$1
 
  # Check for files in the directory
  scripts=($CONFIG_DIR/clients/$CLI_NAME.scripts/*)
  if [ ${#scripts[@]} -gt 0 ]; then 
    # Copy the files to the remote client
    scp $SCP_OPTS -P $SSH_PORT $CONFIG_DIR/clients/$CLI_NAME.scripts/* ${DRLM_USER}@${CLI_NAME}:/var/lib/drlm/scripts/ &> /dev/null
    if [ $? -eq 0 ]; then 
      # Give execution permissions to sctipts
      ssh $SSH_OPTS -p $SSH_PORT ${DRLM_USER}@${CLI_NAME} "chmod 700 /var/lib/drlm/scripts" &> /dev/null
      ssh $SSH_OPTS -p $SSH_PORT ${DRLM_USER}@${CLI_NAME} "chmod 700 /var/lib/drlm/scripts/drlm_*_runbackup_script.sh" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    else 
      return 1; 
    fi
  fi
  return 0
}

function remove_client_scripts () {
  local CLI_NAME=$1
  ssh $SSH_OPTS -p $SSH_PORT ${DRLM_USER}@${CLI_NAME} "rm -rf /var/lib/drlm/scripts/drlm_*_runbackup_script.sh" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function tunning_rear () {

  local REAR_VERSION=$($SUDO rear -V | awk '{print $2}')
  if [ "$REAR_VERSION" == "2.00" ]; then
    if ! grep -q 'https://$DRLM_SERVER/clients/$DRLM_ID/config/default' /usr/share/rear/lib/drlm-functions.sh; then
      $SUDO sed -i 's%https://$DRLM_SERVER/clients/$DRLM_ID%https://$DRLM_SERVER/clients/$DRLM_ID/config/default%g' /usr/share/rear/lib/drlm-functions.sh
    fi
  fi

  # remove cURL verbose to avoid infinite lines of Debug in some cURL versions
  if [ -f "/usr/share/rear/lib/drlm-functions.sh" ]; then
    $SUDO sed -i 's/ $verbose//g' /usr/share/rear/lib/drlm-functions.sh
  fi
  
#  # Solve SELinux autorelabel after recover (RSYNC)
#  if [ -f "/usr/share/rear/restore/default/500_selinux_autorelabel.sh" ]; then
#    if ! grep -v '^\s*$\|^\s*\#' /usr/share/rear/restore/default/500_selinux_autorelabel.sh | grep -q 'rm -rf $TARGET_FS_ROOT/.autorelabel'; then
#      $SUDO sed -i '/^touch \$TARGET_FS_ROOT\/\.autorelabel/i rm -rf \$TARGET_FS_ROOT\/\.autorelabel' /usr/share/rear/restore/default/500_selinux_autorelabel.sh
#    fi
#  fi

  # If rsync reports an error, abort backup process. Only afects rear < 2.0
  if [ -f "/usr/share/rear/backup/RSYNC/default/50_make_rsync_backup.sh" ]; then
      $SUDO sed -i 's/test \"\$_rc\" -gt 0 \&\& VERBOSE\=1 LogPrint \"WARNING !/test \"\$_rc\" -gt 0 \&\& Error \"/g' /usr/share/rear/backup/RSYNC/default/50_make_rsync_backup.sh
  fi
#  if [ -f "/usr/share/rear/backup/RSYNC/default/500_make_rsync_backup.sh" ]; then
#      $SUDO sed -i 's/test \"\$_rc\" -gt 0 \&\& VERBOSE\=1 LogPrint \"WARNING !/test \"\$_rc\" -gt 0 \&\& Error \"/g' /usr/share/rear/backup/RSYNC/default/500_make_rsync_backup.sh
#  fi

  # remove rear cron file (ReaR < 2.5)
  if $SUDO test -f "/etc/cron.d/rear"; then
    $SUDO rm -rf /etc/cron.d/rear
  fi

#  # add drlm setup script for rescue adjustments on migrations
#  $SUDO cat > /tmp/usr_share_rear_skel_default_etc_scripts_system-setup.d_98-drlm-setup-rescue.sh << EOF
## Setting required environment for DRLM proper function
#
#is_true "\$DRLM_MANAGED" || return 0
#
#read -r </proc/cmdline
#
#echo \$REPLY | grep -q "drlm="
#if [ \$? -eq 0 ]; then
#    drlm_cmdline=( \$(echo \${REPLY#*drlm=} | sed 's/drlm=//' | tr "," " ") )
#    for i in \${drlm_cmdline[@]}
#    do
#        if echo \$i | grep -q '^id=\|^server='; then
#          eval \$i
#        fi
#    done
#
#    echo "DRLM_MANAGED: Getting updated rescue configuration from DRLM ..."
#
#    test -n "\$server" && echo "DRLM_SERVER=\$server" >> /etc/rear/rescue.conf
#    test -n "\$id" && echo "DRLM_ID=\$id" >> /etc/rear/rescue.conf
#    test -n "\$server" && echo 'DRLM_REST_OPTS="-H Authorization:\$(cat /etc/rear/drlm.token) -k"' >> /etc/rear/rescue.conf
#
#fi
#EOF

#    if [ -f "/usr/share/rear/skel/default/etc/scripts/system-setup.d/55-migrate-network-devices.sh" ]; then
#      $SUDO sed -i 's/if unattended_recovery \; then/if unattended_recovery \|\| automatic_recovery \; then/g' /usr/share/rear/skel/default/etc/scripts/system-setup.d/55-migrate-network-devices.sh
#    fi

#    $SUDO chmod 644 /tmp/usr_share_rear_skel_default_etc_scripts_system-setup.d_98-drlm-setup-rescue.sh
#    $SUDO chown root:root /tmp/usr_share_rear_skel_default_etc_scripts_system-setup.d_98-drlm-setup-rescue.sh
#    $SUDO cp -p /tmp/usr_share_rear_skel_default_etc_scripts_system-setup.d_98-drlm-setup-rescue.sh /usr/share/rear/skel/default/etc/scripts/system-setup.d/98-drlm-setup-rescue.sh
#    $SUDO rm -f /tmp/usr_share_rear_skel_default_etc_scripts_system-setup.d_98-drlm-setup-rescue.sh
#    if [ $? -eq 0 ]; then return 0; else return 1;fi

#  # control Rsync Port 
#  if [ -f "/usr/share/rear/lib/rsync-functions.sh" ]; then
#    $SUDO sed -i 's/echo 873/echo ${RSYNC_PORT:-874}/g' /usr/share/rear/lib/rsync-functions.sh
#  fi

}

function ssh_tunning_rear () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3

  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO; declare -f tunning_rear); tunning_rear" &> /dev/null
  if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function ssh_rear_drlm_extra () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3

  # add drlm extras
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); $SUDO tar -xf /tmp/drlm-extra.tar -C / && $SUDO rm -f /tmp/drlm-extra.tar"
  if [ $? -eq 0 ]; then return 0; else return 1;fi
    
}

function send_rear_drlm_extra () {

  local USER=$1
  local CLI_NAME=$2
  tar -cf /tmp/drlm-extra.tar -C /usr/share/drlm/conf/rear-extra .
 
  if [ "$CLI_NAME" != "internal" ]; then
    scp $SCP_OPTS -P $SSH_PORT /tmp/drlm-extra.tar ${DRLM_USER}@${CLI_NAME}:/tmp/ &> /dev/null
    if [ $? -ne 0 ]; then AddExitTask "rm -f /tmp/drlm-extra.tar"; return 1; fi
  fi

  return 0
}

function setup_rear_git_dist () {

  local GIT_URL=$1
  # check rear-git present or clone mirror ReaR github repo
  $(git -C /var/lib/drlm/dist/rear branch --show-current >/dev/null 2>&1) || git clone --mirror $GIT_URL /var/lib/drlm/dist/rear >/dev/null 2>&1
  if [ $? -ne 0 ]; then return 1; fi
  git -C /var/lib/drlm/dist/rear remote update >/dev/null 2>&1
  if [ $? -ne 0 ]; then return 1; fi
  # Hold specific commits to go as far as a working codebase permits to have working ReaR point-in-time working builds
  # instead of tagged releases/branches with some missing patches. Interesting for clients with old versions.
  # commit 94016e7 - rear 2.7 date 20240724
  #$(git -C /var/lib/drlm/dist/rear branch --list 2.7_20240724_drlm >/dev/null 2>&1) || git -C /var/lib/drlm/dist/rear branch 2.7_20240724_drlm 94016e7 >/dev/null 2>&1
  branch=$(git -C /var/lib/drlm/dist/rear branch --list 2.7_20240724_drlm)
  [[ -n $branch ]] || git -C /var/lib/drlm/dist/rear branch 2.7_20240724_drlm 94016e7 >/dev/null 2>&1
  if [ $? -eq 0 ]; then return 0; else return 1;fi
}

function install_rear_git () {
  local USER=$1
  local CLI_NAME=$2
  local SUDO=$3
  local GIT_TAG=$4
  local DISTRO_LIKE=$5

  # clone rear git drlm dist
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO GIT_TAG); ( $SUDO bash -c '( [ -d /var/lib/drlm/rear-$GIT_TAG ] && chown -R root:root /var/lib/drlm/rear-$GIT_TAG; git -C /var/lib/drlm/rear-$GIT_TAG branch --show-current >/dev/null 2>&1 ) || $SUDO git clone --branch $GIT_TAG git://$(hostname -s)/rear /var/lib/drlm/rear-$GIT_TAG &> /dev/null' )" &> /dev/null
  if [ $? -ne 0 ]; then return 1; fi
  # install rear git drlm dist
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO GIT_TAG); ( $SUDO make -C /var/lib/drlm/rear-$GIT_TAG uninstall &> /dev/null )" &> /dev/null 
  if [ $? -ne 0 ]; then return 1; fi
  # install rear git drlm dist
  ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO GIT_TAG); ( $SUDO make -C /var/lib/drlm/rear-$GIT_TAG install &> /dev/null )" &> /dev/null 
  if [ $? -ne 0 ]; then return 1; fi
  case "$DISTRO_LIKE" in
    debian|ubuntu)
      # install deps with apt
      #ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO GIT_TAG); ( $SUDO apt-get update &> /dev/null && $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y install \"$(cd /var/lib/drlm/rear-$GIT_TAG/packaging; dpkg-gencontrol -cdebian/control -O 2>/dev/null| egrep 'Depends|Suggests' | awk '{$1=''; print }'| tr -d '\n' | sed 's/ (>= 0)//g;s/,//g;s/ |//g')\" &> /dev/null)" &> /dev/null
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO GIT_TAG); ( $SUDO apt-get update &> /dev/null && for pkg in \$(cd /var/lib/drlm/rear-$GIT_TAG/packaging; dpkg-gencontrol -cdebian/control -O 2>/dev/null| egrep 'Depends|Suggests' | awk '{$1=''; print }'| tr -d '\n' | sed 's/ (>= 0)//g;s/,//g;s/ |//g'); do $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y install \$pkg &> /dev/null; done )" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1;fi
      ;;
    rhel|fedora|centos)
      # install deps with yum
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); ( $SUDO yum -y install \"$(repoquery --depends --resolve rear 2>/dev/null | tr '\n' ' ')\" &>/dev/null )" &> /dev/null
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); ( for pkg in \$(repoquery --queryformat=%{name} --depends --resolve rear); do $SUDO yum -y install \$pkg &>/dev/null; done )" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1;fi
      ;;
    suse)
      # install deps with zypper
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); ( $SUDO zypper --no-gpg-checks in -y \"$(repoquery --depends --resolve rear 2>/dev/null | tr '\n' ' ')\" &>/dev/null )" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1;fi
      ;;
    arch)
      # Install dependencies with pacman
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); ( $SUDO pacman -Sy --noconfirm; for pkg in \$(pactree -u rear | tail -n +2); do $SUDO pacman -S --noconfirm \$pkg &>/dev/null; done )" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1;fi
      ;;
    gentoo)
      # Install dependencies with emerge
      ssh $SSH_OPTS -p $SSH_PORT $USER@$CLI_NAME "$(declare -p SUDO); ( for pkg in \$(equery depgraph rear --quiet | awk '{print \$1}'); do $SUDO emerge --quiet \$pkg &>/dev/null; done )" &> /dev/null
      if [ $? -eq 0 ]; then return 0; else return 1;fi
      ;;
    *)
      return 1
      ;;
  esac

}

function authors () {
    echo "MMMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMWXXNMMMMMMMMMMMMMMMMMMMMWXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMMMMMMMWMWl'..:OKNMMMMMMMMMMMMMMK..oMMMMMMMMMMMMMMMMMMMW;.kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMMMNOo;cMX'....'..;lkNMMMMMMMMMMK..cdloKMKookxlNKdllokNWlcOWdoxOolxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMKl'':d0MMXxdxKWN0xc''c0MMMMMMMMK..cKd.'0O..:doXkldd..oW'.oW'.;Oo..OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMXc.,dNMMMMMMMMMMMMMMMNx,.:KMMMMMMK..oM0..kO..kMM0;.ld..oW'.oW'.lMO..kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMM0,.cNMMMMMMMMMMMMMMMMMMMNo''kMMMMMK.,cd;'cNO..kMMk'.cl..oW'.oW'.lMO..kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMM0'.oMMMMMMMMMMMMMMMMMMMMMMMk'.kMMMMWXNMXKNMMWXXWMMMNKXWNXN0ooNMNXNMWXXWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMW;.:WMMMMMMMMMMMMMMMMMMMMMMMMo.,NMMMMMMMMMMMMMMMMMMMMMMMMMMo.'WMMMMMMMMM;.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMK..OMMMMMMMMMMMMMMMMMMMMMMMMMK..kMMMX;;kMk;:Nk;;lc;ckMNd;;o:.'WKl:c::dK:'.,lWOc:c;l0Mx;;o:cNo:cc:kMMMMMMMMM"
    echo "MMMMMMMO..0MMMMMMMMMMMMMMMMMMMMMMMMMN'.xMMMK..dMx.'Nd..0Mo..Oo..OMo.'WNxox:..KX..dMk..lkc.'Ko..d0Ok.'ldo0MMMMMMMMM"
    echo "MMMMMMMX'.xMMMMMMMMMMMMMMMMMMMMMMMMMO..OMMMK..oWo.'Nd..0Mo..0l..0Mo.'N:.;0l..KX..oWk..o0OodXo..KMMWxodo'.kMMMMMMMM"
    echo "MMMMMMMMl.,NMMMMMMMMMMMMMMMMMMMMMMMW:.:WMMMWc',ll;;Nd..::';xMNl,,l:;;No,,cc;;XWl,':Wk:',,:xWx;;XMMKc,::;lNMMMMMMMM"
    echo "MMMMMMMMN:.;XMMMMMMMMMMMMMMMMMMMMMNc.,XMMMMMMMMMMMMMd..KMMMMMMMMMXxkMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMWWMMMMMMMMMMM"
    echo "MMMMMMMMMNl.,kMMMMMMMMMMMMMMMMMMMO,.:XMMMMMMMMMWXXWW0OXWMMNKKNMMNd.,XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMO:.;xXMMMMMMMMMMMMMXx;.;kWMMMMMMMMMM0..cl'.cMO;'lo';Ox;.'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMM0l'.,lxOkc;:xWMx;.'cOWMMMMMMMMMMMM0..0M:.;N'.'cc,';Wo.;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMMMMW0xl:;'....OM0x0WMMMMMMMMMMMXccK0..0M:.;Wc.'k0klOMo.,ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "MMMMMMMMMMMMMMMMMMMMM0l:ckMMMMMMMMMMMMMMMMMNddNXooXMkoxMWOollokWMXdllXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddxddxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddddddddddoooooooooooooooooo"
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddoooooooooooo"
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkxxkkxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddooooooo"
    echo "kkkkkkkkkkkkxxxxxxxdodxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxddddddddddddddddooo"
    echo "kkkkkkkkkkkkkkkx;.',,..,cxkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkkkOOOkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxddddddddddddddd"
    echo "kkkkkkkkkkkkkkk'.dOOOOOkxlxkkkkkkkkkkOOOOOOOOOOOOOOOOOdc,',:dOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddd"
    echo "kkkkkkkkkkkkkkk..dkxxxkkoodOOOOOOOOOOOOOOOOOOOOOOOOOO,,'.....:OOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxddddddddd"
    echo "kkkkkkkkkkkkkkx,.d:...o:.'xOOOOOOOOOOOOOOO0000000000o:xxxddol.o000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxxxxddddddd"
    echo "OOOOkOOOOOOOOOkoldxkxkkxookOOOOOOO000000000000000000dol;:d::l;k000000000000000000OOOOOOOOOdl:;;;coxkkxxxxxxxxxdddd"
    echo "OOOOOOOOOOOOOOOOoooolc..,cO0000000000000000000000000xxdooxclolkKKKKKKK0000000000000000OOO,,l;;..'..ckkkxxxxxxxxxxd"
    echo "OOOOOOOOOOOOOOOxd;::.;'.,o00000000000000KKKKKKKKKKKKOodo:,;oodKKKKKKKKKKKKKKKK0000000000d.okkkxdxo..kkkkkxxxxxxxxx"
    echo "OOOOOOOOOOOO0kl,,;.. .. '00000000KKKKKKKKKKKKKKKKKKKKd;;cc:;;KKKKKKKKKKKKKKKKKKKKK000000k.o,'lc,,c.;kkkkkkkkxxxxxx"
    echo "O0000O000Okdlol';,....,.:d00KKKKKKKKKKKKKKKKKKKKKKXXX0:'...'cKXXXXXXXXKKKKKKKKKKKKKKK0000;ddododxd,xOkkkkkkkkkxxxx"
    echo "000000OO;,':;.co'  .... ..,ox0KKKKKKKKKKKKKKKXXXXXXXKK0k::cdkKXNXXXXXXXXXXXXXXKKKKKKKKKK0Oc:;',::coOOOOkkkkkkkkxxx"
    echo "000000lO,,,c::';k:,''..';..,;,dKKKKKXXXXXXXXXNXXNNK0KX0xcxdk0KXKNXXNXXXXXXXXXXXXXKKKKKKKK0,';;::''oOOOOOOkkkkkkkkx"
    echo "000000'o:..;;...,d,..:....l';::kKXXXXXXXXXXXXXK0XXKXKX0OO000KKXKK00KXXXXXXXXXXXXXXXKOxdo:,........ ':lxOOOkkkkkkkk"
    echo "00000k.:d',,c,.''ck;,::''':x,;:;0XXXXXXXXXXXK0000O00K0K0OKXK0KKOk0O000XNNXXXXXXXX0:'....... .;.   ......';oOOkkkkk"
    echo "000KK;c.,l...l....cl..:.'..:c...oKXXXXXXXXXXKKX00kO0K00O00K0000OkxO0XKXNNNNNNXXX0.......... ...  ..........,OOkkkk"
    echo "KKKKKk;..':,..'..',x;';;,,',x..';okXXXXXXNNXXXXK0xk0K0000KK0000OkxOKNXXNNNNNNNNX;.   .......    .....   ....dOOOkk"
    echo "KKKKKK,;..;dl......:...,....o.o;oOxl0NNNNNNKKXXKKkdkOxk0OKKOOOOx0K0XNXKNNNNNNNNO...   .....    ....         lOOOOO"
    echo "KKKKKKk,....;:'',..::..:....,cokO0oc'oNNNNN0KKKKK0xOK0O00KK0KKKKKXX0K00NNNNNNNN:...                    .    lOOOOO"
    echo "KKKKKKKk;'..;ko'.'cO0KK0OOOOO0K00OxdldNNNNNK0OO00K00OdllolooodddddO00k0NNNNNNNX....                   .    .kOOOOO"
    echo "KKKKKKKKc.....cl',ckOkc:clllollllloxkONNNNNXxkkOOdoxxkxdl:,',;:::;:xx0NNNNNNNN0....'                       :000OOO"
    echo "KKKKKKXK'....'cddocccoolc;,,;;;;,,;clKNNNNNNN0l:,''',;;:clol:,.'';cNWWWWNNNNNN0...lKc...         ...      ,00000OO"
    echo "KKKKKKXXo..',cllllcc;;;;,,'...OOKNNNNNNNNNNNNNl:,'',',,',,,,,,,;;llXWWWWWWWNNNOloxkO:.... ........       ;0000000O"
    echo "KKKKKXXXO;..'.............. ..dNNNNNNNNNNNNNWKodc;;;;;::::::;:cclolOWWWWWWWWWNXd;::,      .             ,00000000O"
    echo "XKXXXXXXd' ''   . ..  .'....'.:NNNNNNNNNNNWWWKdlcl::ccdoxxddloollooxWWWWWWWWWWNNXO:.                ....'KK0000000"
    echo "XXXXXXXXO'.;:...'..c..':..;.,.'KNNNNNNNNNWWWW0cldxodxddxkdxkdddollloNWWWWWWWWWWNNNd              ...... .KKK000000"
    echo "XXXXXXXXX'..,.  '..;...:..'.,.,kNNNNNNNWWWWWWkdxxxxxkOxxkdoxoooddoooKWWWWWWWWWWWNNo                     ;KKK000000"
    echo "XXXXXXXXk'..c...;. ,,..;,.'.:.,oNNNNNNNWWWWWWOodxxkxkkkxOkkOdxxxoddoNWWWWWWWWWWWWX.                     oKKK000000"
    echo "XXXXXXXXl..',...;  .;..,,...;..dNNNNNNNWWWWWWxdddxkOxkkxkkdxddxxdoddXWWWWWWWWWWWWO                      cKKK000000"
    echo "XXXXXXXXx. .....; ..,...l...:..xNNNNNNNNWWWWW:xxddxkxdxkdxkkxxdddddcOWWWWWWWWWWNNd                      ,KKKK00000"
    echo "XXXXXXXXk      .....:..., .  ..xNNNNNNNNWWWWWc ';:cldddkc:c:clc:,'. 0WWWWWWWWWNNNo                    . ,KKKK00000"
    echo "XXXXXXXXc..'.......     ......'kNNNNNNNNNNNWWk          ..         .NWWWWWNNNNNNN:                      oKKK000000"
    echo "KXXXXXXX'.........krbu  ......'ONNNNNNNNNNNNWK        didac        :WWWWWNNNNNNNN..       pau         ..lKK0000000"
}
