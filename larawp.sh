#!/usr/bin/env bash
################################### SETUP ######################################
#define some colour constants
RED='\033[0;31m'
GREEN='\033[1;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Colour

# path setup
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
USE_COMPOSER=""

#######################################
# helper to install composer packages #
#######################################
function requireComposerPackage(){
	if [[ ${2} = "dev" ]]; then
		COMPOSER_COMMAND_OPTIONS="--dev"
	else
		COMPOSER_COMMAND_OPTIONS=""
	fi

	echo -e "${ORANGE}Installing ${1}...${NC}"
	composer require ${COMPOSER_COMMAND_OPTIONS} $1
	echo -e "${GREEN}Done.${NC}"
	echo ""
}

########################################## END SETUP ####################################################
# get parameters
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -n|--name)
    	PROJECT_NAME="$2"
    shift # past argument
    ;;
    -c|--use-composer)
   		USE_COMPOSER=YES
    ;;
    *)
		# unknown option
		# use the first unrecognised param as the project name if it's not already specified
		if [[ -z "${PROJECT_NAME}" ]]; then
			PROJECT_NAME="${key}"
		else #otherwise throw an error
			echo -e "${RED}Unknown option: ${NC}${key}."
			exit 1
		fi
    ;;
esac
shift # past argument or value
done


if [[ -z ${PROJECT_NAME} ]]; then
	echo -e "${RED}No project name specified${NC}"
	echo -e "${GREEN}Usage: ${NC}${SCRIPT_NAME} <project_name>"
	echo -e "${GREEN}Optional: ${NC}-c|--use-composer force use of composer for laravel install"
	exit 1
fi

echo ""
echo "Detected project name as ${PROJECT_NAME}"
echo ""

while true; do

	echo -e "${GREEN}[1]: ${NC}latest"
	echo -e "${GREEN}[2]: ${NC}5.2.*"
    read -p "Which version of Laravel do you want to install? " VERSION_SELECTION

    case $VERSION_SELECTION in
        [1]* )
        	LARAVEL_VERSION="latest"
        	ROUTES_PATH="routes/web.php"
        break;;
        [2]* )
        	LARAVEL_VERSION="5.2.*"
        	ROUTES_PATH="app/Http/routes.php"
        break;;
        * )
        	echo
        	echo "Please choose a version"
        ;;
    esac
done


PROJECT_DIR="$CURRENT_DIR/${PROJECT_NAME}"
WP_DIR="${PROJECT_DIR}/wordpress"
LARAVEL_APP_DIR="${PROJECT_DIR}/app"
CONTROLLERS_DIR="${LARAVEL_APP_DIR}/Http/Controllers"

#check that we're not trying to create the project in a pre-existing dir
if [ -d "${PROJECT_DIR}" ]; then
	echo -e "${RED}Project directory already exists (${PROJECT_DIR})${NC}"
	exit 1
fi

# check if laravel command is available
if hash laravel 2>/dev/null; then
	LARAVEL_COMMAND_EXISTS=true
else
	LARAVEL_COMMAND_EXISTS=false
fi


# create the laravel project
echo -e "${ORANGE}Creating laravel project...${NC}"
if [[ -z ${USE_COMPOSER} && ${LARAVEL_VERSION} = "latest" && ${LARAVEL_COMMAND_EXISTS} = true ]]; then
	laravel new "${PROJECT_NAME}"
else
	case $LARAVEL_VERSION in
        ["latest"]* )
        	LARAVEL_VERSION="laravel/laravel"
        ;;
        * )
        	LARAVEL_VERSION="laravel/laravel:${LARAVEL_VERSION}"
        ;;

	esac
	composer create-project $LARAVEL_VERSION "${PROJECT_NAME}"
fi
echo -e "${GREEN}Done.${NC}"
echo ""

if [ ! -d "${PROJECT_DIR}" ]; then
	echo -e "${RED}Unable to locate the project directory, aborting.${NC}"
	echo -e "${GREEN}It may be that the laravel new command cannot locate the download (remote server may be down).${NC}"
	echo -e "${GREEN}Try running ${SCRIPT_COMMAND_LOCATION} ${PROJECT_NAME} --use-composer.${NC}"
	exit 1
fi

cd "${PROJECT_DIR}"
# install wordpress
requireComposerPackage "johnpbloch/wordpress":"*"

# install packages via composer

echo -e "${ORANGE}Installing laravelcollective/html...${NC}"
	case $LARAVEL_VERSION in
        "latest" )
        	LARAVELCOLLECTIVE_VERSION="laravelcollective/html"
        ;;
        * )
        	LARAVELCOLLECTIVE_VERSION="laravelcollective/html:5.2.4"
        ;;

	esac

requireComposerPackage ${LARAVELCOLLECTIVE_VERSION}

#corcel
requireComposerPackage "jgrossi/corcel"

#debugbar
requireComposerPackage "barryvdh/laravel-debugbar" dev

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

# add the laravel commands for wordpress
echo -e "${ORANGE}Copying wp:generate-keys artisan command to app/Commands...${NC}"
mkdir "${PROJECT_DIR}/app/Commands/"
cp "${RESOURCE_DIR}/app.commands.WPGenerateKeys.php" "${PROJECT_DIR}/app/Commands/WPGenerateKeys.php"
echo -e "${GREEN}Done.${NC}"
echo ""

#Add Catchall route
#NOTE: This assumes Laravel 5.3 where the routes are in routes/web.php (for WP routes at least)
cd ${PROJECT_DIR}
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

echo -e "${ORANGE}Adding some .gitignore rules...${NC}"
#Add some .gitignore rules
cat <<EOT >> ".gitignore"
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
echo -e "${GREEN}Done.${NC}"
echo ""

#add some items to the .env file
echo -e "${ORANGE}Adding WP_AUTH_xxx keys to .env...${NC}"
cat <<EOT >>  ".env"

# if you've enabled the wp:generate-keys command then you can regenerate these with 'artisan wp:generate-keys'
WP_AUTH_KEY=put_a_secure_key_here
WP_AUTH_SECURE_KEY=put_a_secure_key_here
WP_AUTH_LOGGED_IN_KEY=put_a_secure_key_here
WP_AUTH_NONCE_KEY=put_a_secure_key_here
WP_AUTH_SALT=put_a_secure_key_here
WP_AUTH_SECURE_SALT=put_a_secure_key_here
WP_AUTH_LOGGED_IN_SALT=put_a_secure_key_here
WP_AUTH_NONCE_SALT=put_a_secure_key_here

EOT
echo -e "${GREEN}Done.${NC}"
echo ""

#add some items to the .env.example file
echo -e "${ORANGE}Adding WP_AUTH_xxx keys to .env.example...${NC}"
cat <<EOT >>  ".env.example"

# if you've enabled the wp:generate-keys command then you can regenerate these with 'artisan wp:generate-keys'
WP_AUTH_KEY=put_a_secure_key_here
WP_AUTH_SECURE_KEY=put_a_secure_key_here
WP_AUTH_LOGGED_IN_KEY=put_a_secure_key_here
WP_AUTH_NONCE_KEY=put_a_secure_key_here
WP_AUTH_SALT=put_a_secure_key_here
WP_AUTH_SECURE_SALT=put_a_secure_key_here
WP_AUTH_LOGGED_IN_SALT=put_a_secure_key_here
WP_AUTH_NONCE_SALT=put_a_secure_key_here

EOT
echo -e "${GREEN}Done.${NC}"
echo ""

# Final Instructions
echo -e "${ORANGE}Next Steps: ${NC}"
echo -e "${GREEN}[1]: ${NC}You now need to modify the server config to point the wordpress URLs to below the document root"
echo -e "an example config for apache is located at ${RESOURCE_DIR}/apache-additions.conf${NC}"
echo -e "${GREEN}[2]: ${NC}Modify the .env file in ${PROJECT_DIR}/.env to set database settings (used in ${PROJECT_DIR}/config/wordpress.php) and wp-config.php"
echo -e "${GREEN}[3]: ${NC}Set up the wordpress site via the web interface"
echo ""
echo -e "${ORANGE}Wordpress notes: ${NC}"
echo -e "${GREEN}[*]:${NC} Remember to not make the admin username 'admin' (common hack target)"
echo -e "${GREEN}[*]:${NC} Theme editing is disabled in the wp-config"
echo -e "${GREEN}[*]:${NC} Core auto update is enabled in the wp-config"
echo ""
echo -e "${ORANGE}Laravel notes: ${NC}"
echo -e "${GREEN}[*]:${NC} Read the Corcel documentation at https://packagist.org/packages/jgrossi/corcel"
echo -e "${GREEN}[*]:${NC} to use the artisan command wp:generate-keys, add ${ORANGE}\App\Console\Commands\WPGenerateKeys::class${NC} to the \$commands array in ${ORANGE}${PROJECT_DIR}/app/Console/Kernel.php${NC}"

