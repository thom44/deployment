#! /bin/bash
# DRUPAL 8 STAGE REBUILD SCRIPT #
##################################

# You may run this script as sudo to change file owner
# sudo ./stage-rebuild.sh

# Production drush alias
PROD_ALIAS=@deploy.prod

# Stage drush alias
STAGE_ALIAS=@deploy.stage

# Set filesystem user:group according your server configuration
DRUPAL_USER=thom
DRUPAL_GROUP=www-data

# Stage site Directory - relative from drupal-root
SITE_DIR=sites/default

# If you use the following structure, than you don't need to edit below.
# project/deployment/stage-rebuild.sh = location of this file
# project/web = Drupal root directory
# project/.git = location of your git repositority
# project/dumps = the location where the dumps are saved
# project/vendor = composer vendor directory
# project/composer.json

#**********************************************************************#
# Checkout absolute project path
# Works if this file is located in subdirectory of project path
cd ..
PROJECT_PATH=$(pwd)

DRUPAL_DIR=web

DRUPAL_ROOT=$PROJECT_PATH/$DRUPAL_DIR

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

# Set Page to Maintenance Mode
drush $STAGE_ALIAS sset system.maintenance_mode TRUE 2>&1 | tee -a $logfile

echo "drush sql-sync $PROD_ALIAS $STAGE_ALIAS"
if prompt_yes_no "Do you want to DESTROY DATABASE $DB_STAGE AND REPLACE IT WITH $DB_PROD" ; then

  if prompt_yes_no "Do you want to backup the Stage Database" ; then
    drush $STAGE_ALIAS sql-dump --result-file=$PROJECT_PATH/dumps/stage-$now.sql
  fi

  drush sql-sync $PROD_ALIAS $STAGE_ALIAS 2>&1 | tee -a $logfile

fi

if prompt_yes_no "Do you want to PULL THE GIT REPOSITORY" ; then
  
  cd $PROJECT_PATH;

  git pull origin master 2>&1 | tee -a $logfile
  
  chown -R $DRUPAL_USER:$DRUPAL_GROUP . 2>&1 | tee -a $logfile

  composer install 2>&1 | tee -a $logfile

  drush $STAGE_ALIAS updb 2>&1 | tee -a $logfile

fi


if prompt_yes_no "Do you want to IMPORT CONFIGURATION" ; then
  
  drush $STAGE_ALIAS config-import 2>&1 | tee -a $logfile

fi

echo "Producton files directory"

if prompt_yes_no "Do you want to DESTROY STAGE FILES DIR AND REPLACE IT WITH PROD FILES DIR" ; then

  drush rsync $PROD_ALIAS:%files/ $STAGE_ALIAS:%files
  # fix user:group if nessersary
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

# Clear all caches
drush $STAGE_ALIAS cr 2>&1 | tee -a $logfile

if prompt_yes_no "Do you want to SET THE MAINTENANCE_MODE TO ONLINE" ; then

  drush $STAGE_ALIAS sset system.maintenance_mode FALSE 2>&1 | tee -a $logfile

fi

