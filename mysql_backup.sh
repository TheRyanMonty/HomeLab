#!/bin/bash
################################################################################
##
##      sftp_client.sh
##
################################################################################
#Usage:
#CRON:
  # Example cron job for daily db backup at midnight
  # min  hr mday month wday command
  # 0    0  *    *     *    /Users/[your user name]/scripts/mysql_backup.sh

#RESTORE FROM BACKUP
#  zcat [backupfile.sql.gz] | mysql -u [uname] -p[pass] [dbname]

################################################################################
## Config SETTINGS
################################################################################

# Directory to store the backup files
BACKUP_DIR=/var/nfs/backups/mysql_backups/wordpress_db/

# MYSQL Parameters
MYSQL_UNAME=root
MYSQL_PWORD=qOskT1&%lOo0

#Server hosting the database(s)
MYSQL_SERVER=192.168.86.55
MYSQL_PORT=8003

# Don't backup databases with these names 
# Example: starts with mysql (^mysql) or ends with _schema (_schema$)
IGNORE_DB="(^mysql|_schema$)"

# include mysql and mysqldump binaries for cron bash user
PATH=$PATH:/usr/bin/mysql

# Number of days to keep backups
KEEP_BACKUPS_FOR=30 #days

# YYYY-MM-DD
TIMESTAMP=$(date +%F)

################################################################################
## Functions
################################################################################

function delete_old_backups()
{
  echo "Deleting $BACKUP_DIR/*.sql.gz older than $KEEP_BACKUPS_FOR days"
  find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;
}

function mysql_login() {
  local mysql_login="-u $MYSQL_UNAME" 
  if [ -n "$MYSQL_PWORD" ]; then
    local mysql_login+=" -p$MYSQL_PWORD" 
  fi
  echo $mysql_login
}

function database_list() {
  local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
  echo $(mysql $(mysql_login) -e "$show_databases_sql"|awk -F " " '{if (NR!=1) print $1}')
}

function echo_status(){
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

function backup_database(){
    backup_file="$BACKUP_DIR/$TIMESTAMP.$database.sql.gz" 
    output+="$database => $backup_file\n"
    echo_status "...backing up $count of $total databases: $database"
    $(mysqldump $(mysql_login) $database | gzip -9 > $backup_file)
}

function backup_databases(){
  local databases=$(database_list)
  local total=$(echo $databases | wc -w | xargs)
  local output=""
  local count=1
  for database in $databases; do
    backup_database
    local count=$((count+1))
  done
  echo -ne $output | column -t
}

function hr(){
  printf '=%.0s' {1..100}
  printf "\n"
}

###########################################################
### Main execution area
###########################################################
delete_old_backups
hr
backup_databases
hr
printf "All backed up!\n\n"