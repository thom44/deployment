<?php
/**
 * @file 
 * Drush alias file example with minimal configuration
 *   this is all you need for the rebuild-scripts are working
 * @Todo
 *   1. Rename this file and change "mygroup" to your projectname
 *   2. Change the 'uri' and 'root' values
 */

/**
 * Alias for production envirement
 */
$aliases['prod'] = array(
	'uri' => 'prod.local',
	'root' => '/path/to/the/prod-project/web',
);

/** 
 * Alias for staging envirement
 */
$aliases['stage'] = array(
	'uri' => 'stage.local',
	'root' => '/path/to/the/stage-project/web',
);



