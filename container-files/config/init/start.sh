#!/bin/sh
set -eu
export TERM=xterm

# Bash Colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
white=`tput setaf 7`
bold=`tput bold`
reset=`tput sgr0`
separator=$(echo && printf '=%.0s' {1..100} && echo)

#OS VARIABLES
INSTALL_DIR='/opt/atlassian/jira'

# Functions
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[JIRA-LOG `date +'%T'`]${reset} $@";
  else echo; fi
}
stop_jira() {
  log "Stopping Jira"
  /opt/atlassian/jira/bin/stop-jira.sh
  log "Jira Stopped"
}
install_jira() {
  cd /tmp
  ./jira.bin <<<"o
1
i
"
  log "JIRA server installed."
  stop_jira
}
get_mysql_connector() {
  log "Downloading mysql-connector."
  curl -L http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.tar.gz -o /tmp/mysql-connector-java-5.1.37.tar.gz
  mkdir -p /tmp/mysql-connector/
  tar zxvf /tmp/mysql-connector-java-5.1.37.tar.gz -C /tmp/mysql-connector/ --strip-components=1
  cp /tmp/mysql-connector/mysql-connector-java-5.1.37-bin.jar ${INSTALL_DIR}/lib/
  log "mysql-connector Installed."
}
prepare_mysql_database() {
  log "Creating and configuring MYSQL database"
  MYSQL_CONN="mysql -u $MARIADB_USER -p$MARIADB_PASS -h $JIRA_DB_ADDRESS -e "
  ${MYSQL_CONN} "CREATE DATABASE $JIRA_DB_NAME CHARACTER SET utf8 COLLATE utf8_bin;"
  ${MYSQL_CONN} "GRANT ALL on ${JIRA_DB_NAME}.* TO '${JIRA_USER}'@'%' IDENTIFIED BY '${JIRA_PASS}';"
  ${MYSQL_CONN} "FLUSH PRIVILEGES;"
  log "MYSQL database updated."
}
clean_all() {
  log "Removing all temporary files."
  rm -rf /tmp/mysql-connector-java-5.1.37.tar.gz
  rm -rf /tmp/mysql-connector/
  rm -rf /tmp/jira.bin
  log "All cleaned. System ready! "
}
### Magic Starts here
## Install Jira Server
install_jira
## Check Supported version of database specified by user on docker run.
if [[ ${DB_SUPPORT} == "mysql" || ${DB_SUPPORT} == "mariadb" ]]; then
  prepare_mysql_database
  get_mysql_connector
fi
## Clean all installation directories from trash.
clean_all
