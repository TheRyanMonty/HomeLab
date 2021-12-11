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
  # 0    0  *    *     *    /<script_path>/mysql_backup.sh -c <conf_file_path>/<name>.conf

#RESTORE FROM BACKUP
#  zcat [backupfile.sql.gz] | mysql -u [uname] -p[pass] [dbname]

################################################################################
## Functions
################################################################################

ImportGlobalFunctions () {
############################################################################
### ImportGlobalFunctions - Purpose is to import needed functions
############################################################################
#Define script execution directory for Importing Global Functions
script_dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

#Importing functions
for func_file in ${script_dir}/funcs/*.func; do
	source ${func_file}
done
}

DeleteOldBackups () {
  echo "Deleting $BACKUP_DIR/*.sql.gz older than $KEEP_BACKUPS_FOR days"
  find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;
  CaptureExitCode
  VerifyExitCode
}

MysqlLogin() {
  local mysql_login="-u $MYSQL_UNAME" 
  if [ -n "$MYSQL_PWORD" ]; then
    local mysql_login+=" -p$MYSQL_PWORD" 
  fi
  echo $mysql_login
}

DatabaseList() {
  local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
  echo $(mysql $(mysql_login) -e "$show_databases_sql"|awk -F " " '{if (NR!=1) print $1}')
}

EchoStatus() {
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

BackupDatabase() {
    backup_file="$BACKUP_DIR/$TIMESTAMP.$database.sql.gz" 
    output+="$database => $backup_file\n"
    echo_status "...backing up $count of $total databases: $database"
    $(mysqldump $(mysql_login) $database | gzip -9 > $backup_file)
    CaptureExitCode
    VerifyExitCode
}

BackupDatabases() {
  local databases=$(database_list)
  local total=$(echo $databases | wc -w | xargs)
  local output=""
  local count=1
  for database in $databases; do
    backup_database
    CaptureExitCode
    VerifyExitCode
    local count=$((count+1))
  done
  echo -ne $output | column -t
}

hr() {
  printf '=%.0s' {1..100}
  printf "\n"
}

###########################################################
### Main execution area
###########################################################
ImportGlobalFunctions
delete_old_backups
hr
backup_databases
hr
printf "All backed up!\n\n"