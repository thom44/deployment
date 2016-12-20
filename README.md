# deployment
# This are Drupal 8 rebuild scripts based on a install with composer template
# Example command 
$ composer create-project drupal-composer/drupal-project:8.x-dev $DRUPAL_DIR --stability dev --no-interaction
@see https://github.com/drupal-composer/drupal-project

# Structure in your project directory after composer template install
* /drush
* /scripts
* /vendor
* /web = Drupal Root 
* composer.json
* composer.lock

# You can add the following to your project directory
* /deployment (chmod 700)
* /dumps (chmod 700)
* .git = Initialize your project git repository here
* .gitignore = rename the example.gitignore

# You can also configure your config directory for the Drupal configuraton management
# to the project directory, to get it out of web accessable location
* /config/sync (chmod 770) 
# To tell Drupal this location, change in settings.php
$config_directories['sync'] = '../config/sync';

# --- The Concept --- #
# We deploy the following
* composer.json
* comoposer.lock
* custom themes and modules
# We do not deploy 
* vendor (Libraries)
* Drupal core
* Drupal contrib themes and modules
@see example.gitignore

# Composer handling
# - We run composer update only on development,
#   which updates all project according composer.json
# - On production, we run only composer install
#   which synronize all projects with composer.lock.
#   That means the exact same version as tested on development. 
#   ! We run never composer update on production !

# --- Workflow --- #
# On development
* Make development changes
* run $ drush config-export
* git add, commit and push
# For updates on development use
* $ composer require
* $ composer update

# run /deployment/stage-rebuild.sh on stage enviroment
# Configure the stage-rebuild.sh to your envirement
$ sudo ./stage-rebuild.sh
# This will do the following
* set maintance-mode TRUE
* Dump the stage database
* Remove stage database and import the fresh production database
* Remove the Drupal /files directory and replace it with the production one
* Pull the repository 
* run $ composer install
* run $ drush updatedb
* run $ drush config-import to import the configuration changes
* run some security checks @see stage-rebuild.sh itself
* set maintance-mode FALSE
# Than you have all new changes with the production database and files
# You can test it!

# run /deployment/prod-rebuild.sh on production enviroment
# Configure the prod-rebuild.sh to your envirement
$ sudo ./prod-rebuild.sh
# This will do the following
* set maintance-mode TRUE
* Backup the web directory and the current composer.lock file
* Dump the producton database
* Pull the repository 
* run $ composer install
* run $ drush updatedb
* run $ drush config-import to import the configuration changes
* run some security checks @see stage-rebuild.sh itself
* set maintance-mode FALSE
# Now you should have the same reslult as testet on you stage enviremone.
# Good look!

