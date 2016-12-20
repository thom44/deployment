#! /bin/bash
# DRUPAL 8 STAGE REBUILD SCRIPT #
##################################

# Run this script as sudo
# sudo ./stage-rebuild.sh

# Define the PRODUCTION database
DB_PROD=production-db-name

# Define the STAGE database
# !!! THIS DATABASE WILL BE DELETET DURING REBUILD !!!
DB_STAGE=stage-db-name

# Database Character set
CHARACTER=utf8
COLLATE=utf8_general_ci
#CHARACTER=utf8mb4
#COLLATE=utf8mb4_general_ci

# Server Database
# ! This works if stage and prod are at the this server !
db_user=database-user
db_password="db-password"
db_host=localhost

# Set filesystem user:group
DRUPAL_USER=webfile-owner-username
DRUPAL_GROUP=webfile-group

# Site Directory - relative from drupal-root
SITE_DIR=sites/default

# If you use the following structure, than you don't need to edit below.
# project/deployment/stage-rebuild.sh = location of this file
# project/web = Drupal root directory
# project/.git = location of your git repositority
# project/dumps = the location where the dumps are saved
# project/vendor = composer vendor directory
# porject/composer.json

#**********************************************************************#
# Checkout absolute project path
# Works if this file is located in subdirectory of project path
cd ..
PROJECT_PATH=$(pwd)

DRUPAL_DIR=web

DRUPAL_ROOT=$PROJECT_PATH/$DRUPAL_DIR

# PROD location Directory
PROD_LOCATION=/path/to/your/poduction/site/web/sites/default
PROD_FILES=$PROD_LOCATION/files

#---------- do not edit below ------------
# simple prompt
prompt_yes_no() {
  while true ; do
printf "$* [Y/n] "
    read answer
    if [ -z "$answer" ] ; then
return 0
    fi
case $answer in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      [Nn]|[Nn][Oo])
        return 1
        ;;
      *)
        echo "Please answer yes or no"
        ;;
    esac
done
}

now=$(date +"%d_%m_%Y__%H_%M_%S")

### Creates subdirectory for logfiles
LOG_DIR=logs

if [ ! -d $PROJECT_PATH/deployment/$LOG_DIR ]; then
    mkdir $PROJECT_PATH/deployment/$LOG_DIR
    chmod 700 $PROJECT_PATH/deployment/$LOG_DIR
fi

logfile=$PROJECT_PATH/deployment/$LOG_DIR/stage-rebuild-$now.log

echo "Time is $now"   2>&1 | tee -a $logfile
echo "Drupal Root is $DRUPAL_ROOT"  2>&1 | tee -a $logfile
echo "Logfile is $logfile"

# Change to Drupal root directory
cd $DRUPAL_ROOT;

# Set Page to Maintenance Mode
drush sset system.maintenance_mode TRUE 2>&1 | tee -a $logfile

if prompt_yes_no "Do you want to DESTROY DATABASE $DB_STAGE AND REPLACE IT WITH $DB_PROD" ; then

  mysqldump --user=$db_user --host=$db_host --password=$db_password $DB_PROD > $PROJECT_PATH/dumps/tmp_"$DB_PROD"_$now.sql 2>&1 | tee -a $logfile

  mysqldump --user=$db_user --host=$db_host --password=$db_password $DB_STAGE > $PROJECT_PATH/dumps/dump_bevor_rebuild_"$DB_STAGE"_$now.sql 2>&1 | tee -a $logfile

  chmod 400 $PROJECT_PATH/dumps/dump_bevor_rebuild_"$DB_STAGE"_$now.sql 2>&1 | tee -a $logfile

  mysqladmin --user=$db_user --host=$db_host --password=$db_password DROP $DB_STAGE; 2>&1 | tee -a $logfile

  # Create Database
  mysql --user=$db_user --host=$db_host --password=$db_password -Bse "CREATE DATABASE IF NOT EXISTS $DB_STAGE CHARACTER SET $CHARACTER COLLATE $COLLATE;" 2>&1 | tee -a $logfile

  mysql --user=$db_user --host=$db_host --password=$db_password $DB_STAGE < ../dumps/tmp_"$DB_PROD"_$now.sql 2>&1 | tee -a $logfile

  chmod 400 $PROJECT_PATH/dumps/tmp_"$DB_PROD"_$now.sql 2>&1 | tee -a $logfile

fi


if prompt_yes_no "Do you want to PULL THE GIT REPOSITORY" ; then
  
  cd $PROJECT_PATH;

  git pull origin master 2>&1 | tee -a $logfile
  
  chown -R $DRUPAL_USER:$DRUPAL_GROUP . 2>&1 | tee -a $logfile

  composer install 2>&1 | tee -a $logfile

  cd $DRUPAL_ROOT;

  drush updb 2>&1 | tee -a $logfile

fi


if prompt_yes_no "Do you want to IMPORT CONFIGURATION" ; then
  
  drush config-import 2>&1 | tee -a $logfile

fi

echo "Producton files directory"
echo $PROD_FILES;
echo "rsync -av  --exclude=php,css,js $PROD_LOCATION/files/ $DRUPAL_ROOT/$SITE_DIR/files"

if prompt_yes_no "Do you want to DESTROY STAGE FILES DIR AND REPLACE IT WITH PROD FILES DIR" ; then

  rsync -av --exclude=php,css,js $PROD_LOCATION/files/ $DRUPAL_ROOT/$SITE_DIR/files

  chown -R $DRUPAL_USER:$DRUPAL_GROUP $DRUPAL_ROOT/$SITE_DIR/files 2>&1 | tee -a $logfile

fi

echo "Make some security check" 2>&1 | tee -a $logfile

# Make shure the config files are protected
chmod 440 $DRUPAL_ROOT/$SITE_DIR/settings.php 2>&1 | tee -a $logfile
if [ -f $DRUPAL_ROOT/$SITE_DIR/services.yml ]; then
    chmod 440 $DRUPAL_ROOT/$SITE_DIR/services.yml 2>&1 | tee -a $logfile
fi
if [ -f $DRUPAL_ROOT/$SITE_DIR/settings.local.php ]; then
    chmod 440 $DRUPAL_ROOT/$SITE_DIR/settings.local.php 2>&1 | tee -a $logfile
fi

# Check of .git directory contains a .htaccess file for security
if [ ! -f $PROJECT_PATH/.git/.htaccess ]; then
     cp $PROJECT_PATH/deployment/.htaccess $PROJECT_PATH/.git/.htaccess 2>&1 | tee -a $logfile
     echo ".git/.htaccess created for security" 2>&1 | tee -a $logfile
else
     echo ".git/.htaccess file exists already" 2>&1 | tee -a $logfile
fi

cd $DRUPAL_ROOT;

# Clear all caches
drush cr 2>&1 | tee -a $logfile

if prompt_yes_no "Do you want to SET THE MAINTENANCE_MODE TO ONLINE" ; then

  drush sset system.maintenance_mode FALSE 2>&1 | tee -a $logfile

fi

