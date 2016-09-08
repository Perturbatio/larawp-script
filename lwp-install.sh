#!/usr/bin/env bash

CURRENT_DIR="$( pwd )"
SCRIPT_COMMAND_LOCATION="${BASH_SOURCE[0]}"
SCRIPT_NAME="$( basename "${SCRIPT_COMMAND_LOCATION}" )"

#determine if the script was run via a symlink
SYMLINK_DESTINATION=`readlink ${SCRIPT_COMMAND_LOCATION}`

if [[ -z $SYMLINK_DESTINATION ]]; then
	#not using symlink
	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
	#using symlink
	SCRIPT_DIR="$( cd "$( dirname "${SYMLINK_DESTINATION}" )" && pwd )"
fi

RESOURCE_DIR="$SCRIPT_DIR/resources"
PROJECT_NAME="$1"

#define some colour constants
RED='\033[0;31m'
GREEN='\033[1;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Colour

if [[ -z ${PROJECT_NAME} ]]; then
	echo -e "${RED}No project name specified${NC}"
	echo -e "${GREEN}Usage: ${NC}${SCRIPT_NAME} <project_name>"
	exit 1
fi

PROJECT_DIR="$CURRENT_DIR/${PROJECT_NAME}"
WP_DIR="${PROJECT_DIR}/wordpress"
LARAVEL_APP_DIR="${PROJECT_DIR}/app"
CONTROLLERS_DIR="${LARAVEL_APP_DIR}/Http/Controllers"
ROUTES_PATH="${PROJECT_DIR}/routes/web.php"

# create the laravel project
echo -e "${ORANGE}Creating laravel project...${NC}"
laravel new "${PROJECT_NAME}"
echo -e "${GREEN}Done.${NC}"
echo ""

cd "${PROJECT_NAME}"
# install wordpress
echo -e "${ORANGE}Installing wordpress...${NC}"
composer require "johnpbloch/wordpress":"*"
echo -e "${GREEN}Done.${NC}"
echo ""

# install packages via composer

echo -e "${ORANGE}Installing laravelcollective/html...${NC}"
composer require "laravelcollective/html":"5.3.*"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Installing jgrossi/corcel...${NC}"
composer require jgrossi/corcel
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Patching laravel index.php...${NC}"
cd "${PROJECT_DIR}/public"
patch -u < "${RESOURCE_DIR}/laravel.index.patch"
echo -e "${GREEN}Done.${NC}"
echo ""

cd "${PROJECT_DIR}"

echo -e "${ORANGE}Creating wp-config.php with laravel mods...${NC}"
cp "${RESOURCE_DIR}/wp-config-laravel.php" "$WP_DIR/wp-config.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying wp-bootstrap-laravel.php...${NC}"
cp "${RESOURCE_DIR}/wordpress.wp-bootstrap-laravel.php" "$WP_DIR/wp-bootstrap-laravel.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying laravel based wordpress config file...${NC}"
cp "${RESOURCE_DIR}/config.wordpress.php" "${PROJECT_DIR}/config/wordpress.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying Wordpress helper class to app/Libraries...${NC}"
mkdir "${PROJECT_DIR}/app/Libraries/"
cp "${RESOURCE_DIR}/app.libraries.Wordpress.php" "${PROJECT_DIR}/app/Libraries/Wordpress.php"
echo -e "${GREEN}Done.${NC}"
echo ""

# Add Catchall controller
echo -e "${ORANGE}Copying ${RESOURCE_DIR}/CatchallController.php to ${CONTROLLERS_DIR}/CatchallController.php...${NC}"
cp "${RESOURCE_DIR}/CatchallController.php" "${CONTROLLERS_DIR}/CatchallController.php"
echo -e "${GREEN}Done.${NC}"
echo ""

#Add Catchall route
#NOTE: This assumes Laravel 5.3 where the routes are in routes/web.php (for WP routes at least)
cat <<EOT >>  "${ROUTES_PATH}"

/**************************************************************
 fallback to catchall controller if no other route matches and
 let it deal with the request.

 NOTE: you must ensure that this is the last route defined
 otherwise it will override any that follow it.
**************************************************************/
Route::any( '{catchall}', [
	'uses'   => 'CatchallController@index',
] )->where( 'catchall', '(.*)' );

EOT

#Add some .gitignore rules
cat <<EOT >> "${PROJECT_DIR}/.gitignore"
#laravel related files
storage/debugbar
.env

# build tools
/node_modules

# phpstorm project dir
.idea

# wordpress related files
/wordpress/wp-admin/
/wordpress/wp-includes/
/wordpress/index.php
/wordpress/wp-activate.php
/wordpress/wp-comments-post.php
/wordpress/wp-cron.php
/wordpress/xmlrpc.php
/wordpress/license.txt
/wordpress/wp-config-sample.php
/wordpress/wp-login.php
/wordpress/wp-signup.php
/wordpress/readme.html
/wordpress/wp-blog-header.php
/wordpress/wp-links-opml.php
/wordpress/wp-mail.php
/wordpress/wp-trackback.php
/wordpress/wp-load.php
/wordpress/wp-settings.php
/wordpress/wp-content/uploads

# some special git files
.gitattributes
.gitconfig

# ignore server related files
.bash_history
.bash_logout
.bash_profile
.bash_aliases
.bashrc
.nanorc
.emacs
.ssh/
Maildir/
etc/
fcgi-bin/
logs/
ssl.cert
ssl.key
private
backups
db-imports
/.subversion
/.composer
/.lesshst

#local server files
.bash_aliases
.cache/
.profile
.usermin/

EOT

# Final Instructions
echo -e "${ORANGE}Next Steps: ${NC}"
echo -e "${GREEN}[1]: ${NC}You now need to modify the server config to point the wordpress URLs to below the document root"
echo -e "an example config for apache is located at ${RESOURCE_DIR}/apache-additions.conf${NC}"
echo -e "${GREEN}[2]: ${NC}Modify the wordpress config file in ${PROJECT_DIR}/config/wordpress.php"
echo -e "${GREEN}[3]: ${NC}Set up the wordpress site via the web interface"
echo ""
echo -e "${ORANGE}Wordpress notes: ${NC}"
echo -e "${GREEN}[*]:${NC} Remember to change the admin username to something else (admin is too common)"
echo -e "${GREEN}[*]:${NC} Theme editing is disabled in the wp-config"
echo -e "${GREEN}[*]:${NC} Core auto update is enabled in the wp-config"
echo ""
echo -e "${ORANGE}Laravel notes: ${NC}"
echo -e "${GREEN}[*]:${NC} Read the Corcel documentation at https://packagist.org/packages/jgrossi/corcel"
echo -e "${GREEN}[*]:${NC} You may want to install barryvdh/laravel-debugbar to aid in development"

