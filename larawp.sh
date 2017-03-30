#!/usr/bin/env bash
################################### SETUP ######################################
#define some colour constants
red='\033[0;31m'
green='\033[1;32m'
orange='\033[0;33m'
nocolour='\033[0m' # No Colour

# path setup
current_dir="$( pwd )"
script_command_location="${BASH_SOURCE[0]}"
script_name="$( basename "${script_command_location}" )"

#determine if the script was run via a symlink
symlink_destination=`readlink ${script_command_location}`

if [[ -z $symlink_destination ]]; then
	#not using symlink
	script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
	#using symlink
	script_dir="$( cd "$( dirname "${symlink_destination}" )" && pwd )"
fi

resource_dir="$script_dir/resources"
use_composer=""

#######################################
# helper to install composer packages #
#######################################
function requireComposerPackage(){
	if [[ ${2} = "dev" ]]; then
		composer_command_options="--dev"
	else
		composer_command_options=""
	fi

	echo -e "${orange}Installing ${1}...${nocolour}"
	composer require ${composer_command_options} $1
	echo -e "${green}Done.${nocolour}"
	echo ""
}

########################################## END SETUP ####################################################
# get parameters
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -n|--name)
    	project_name="$2"
    shift # past argument
    ;;
    -c|--use-composer)
   		use_composer=YES
    ;;
    *)
		# unknown option
		# use the first unrecognised param as the project name if it's not already specified
		if [[ -z "${project_name}" ]]; then
			project_name="${key}"
		else #otherwise throw an error
			echo -e "${red}Unknown option: ${nocolour}${key}."
			exit 1
		fi
    ;;
esac
shift # past argument or value
done


if [[ -z ${project_name} ]]; then
	echo -e "${red}No project name specified${nocolour}"
	echo -e "${green}Usage: ${nocolour}${script_name} <project_name>"
	echo -e "${green}Optional: ${nocolour}-c|--use-composer force use of composer for laravel install"
	exit 1
fi

echo ""
echo "Detected project name as ${project_name}"
echo ""

while true; do

	echo -e "${green}[1]: ${nocolour}latest"
	echo -e "${green}[2]: ${nocolour}5.2.*"
    read -p "Which version of Laravel do you want to install? " version_selection

    case $version_selection in
        [1]* )
        	laravel_version="latest"
        	routes_path="routes/web.php"
        break;;
        [2]* )
        	laravel_version="5.2.*"
        	routes_path="app/Http/routes.php"
        break;;
        * )
        	echo
        	echo "Please choose a version"
        ;;
    esac
done


project_dir="$current_dir/${project_name}"
wp_dir="${project_dir}/wordpress"
laravel_app_dir="${project_dir}/app"
controllers_dir="${laravel_app_dir}/Http/Controllers"

#check that we're not trying to create the project in a pre-existing dir
if [ -d "${project_dir}" ]; then
	echo -e "${red}Project directory already exists (${project_dir})${nocolour}"
	exit 1
fi

# check if laravel command is available
if hash laravel 2>/dev/null; then
	laravel_command_exists=true
else
	laravel_command_exists=false
fi


# create the laravel project
echo -e "${orange}Creating laravel project...${nocolour}"
if [[ -z ${use_composer} && ${laravel_version} = "latest" && ${laravel_command_exists} = true ]]; then
	laravel new "${project_name}"
else
	case $laravel_version in
        ["latest"]* )
        	laravel_version="laravel/laravel"
        ;;
        * )
        	laravel_version="laravel/laravel:${laravel_version}"
        ;;

	esac
	composer create-project $laravel_version "${project_name}"
fi
echo -e "${green}Done.${nocolour}"
echo ""

if [ ! -d "${project_dir}" ]; then
	echo -e "${red}Unable to locate the project directory, aborting.${nocolour}"
	echo -e "${green}It may be that the laravel new command cannot locate the download (remote server may be down).${nocolour}"
	echo -e "${green}Try running ${script_command_location} ${project_name} --use-composer.${nocolour}"
	exit 1
fi

cd "${project_dir}"
# install wordpress
requireComposerPackage "johnpbloch/wordpress":"*"

# install packages via composer

echo -e "${orange}Installing laravelcollective/html...${nocolour}"
	case $laravel_version in
        "latest" )
        	laravelcollective_version="laravelcollective/html"
        ;;
        * )
        	laravelcollective_version="laravelcollective/html:5.2.4"
        ;;

	esac

requireComposerPackage ${laravelcollective_version}

#corcel
requireComposerPackage "jgrossi/corcel"

#debugbar
requireComposerPackage "barryvdh/laravel-debugbar" dev

echo -e "${orange}Patching laravel index.php...${nocolour}"
cd "${project_dir}/public"
patch -u < "${resource_dir}/laravel.index.patch"
echo -e "${green}Done.${nocolour}"
echo ""

cd "${project_dir}"

echo -e "${orange}Copying files to wordpress dir...${nocolour}"
cp "${resource_dir}/wordpress/"* "$wp_dir/"
echo -e "${green}Done.${nocolour}"
echo ""

echo -e "${orange}Copying laravel config files...${nocolour}"
cp "${resource_dir}/config/"* "${project_dir}/config/"
echo -e "${green}Done.${nocolour}"
echo ""

echo -e "${orange}Copying Libraries to app/Libraries...${nocolour}"
mkdir "${project_dir}/app/Libraries/"
cp "${resource_dir}/app.Libraries/"* "${project_dir}/app/Libraries/"
echo -e "${green}Done.${nocolour}"
echo ""

echo -e "${orange}Copying Listeners to app/Listeners...${nocolour}"
cp "${resource_dir}/app.Listeners/"* "${project_dir}/app/Listeners"
echo -e "${green}Done.${nocolour}"
echo ""

echo -e "${orange}Copying Providers to app/Providers...${nocolour}"
cp "${resource_dir}/app.Providers/"* "${project_dir}/app/Providers"
echo -e "${green}Done.${nocolour}"
echo ""

# Add Catchall controller
echo -e "${orange}Copying Controllers...${nocolour}"
cp "${resource_dir}/app.Http.Controllers/"* "${controllers_dir}/"
echo -e "${green}Done.${nocolour}"
echo ""

# add the laravel commands for wordpress
#todo: check that this works with the latest laravel
echo -e "${orange}Copying console commands to app/Console/Commands...${nocolour}"
mkdir "${project_dir}/app/Console/Commands/"
cp "${resource_dir}/app.Console.Commands/"* "${project_dir}/app/Console/Commands/"
echo -e "${green}Done.${nocolour}"
echo ""

#Add Catchall route
#NOTE: This assumes Laravel 5.3 where the routes are in routes/web.php (for WP routes at least)
cd ${project_dir}
cat <<EOT >>  "${routes_path}"

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

echo -e "${orange}Adding some .gitignore rules...${nocolour}"
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
echo -e "${green}Done.${nocolour}"
echo ""

#add some items to the .env file
echo -e "${orange}Adding WP_AUTH_xxx keys to .env...${nocolour}"
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
echo -e "${green}Done.${nocolour}"
echo ""

#add some items to the .env.example file
echo -e "${orange}Adding WP_AUTH_xxx keys to .env.example...${nocolour}"
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
echo -e "${green}Done.${nocolour}"
echo ""

# Final Instructions
echo -e "${orange}Next Steps: ${nocolour}"
echo -e "${green}[1]: ${nocolour}You now need to modify the server config to point the wordpress URLs to below the document root"
echo -e "an example config for apache is located at ${resource_dir}/apache-additions.conf${nocolour}"
echo -e "${green}[2]: ${nocolour}Modify the .env file in ${project_dir}/.env to set database settings (used in ${project_dir}/config/wordpress.php) and wp-config.php"
echo -e "${green}[3]: ${nocolour}Set up the wordpress site via the web interface"
echo ""
echo -e "${orange}Wordpress notes: ${nocolour}"
echo -e "${green}[*]:${nocolour} Remember to not make the admin username 'admin' (common hack target)"
echo -e "${green}[*]:${nocolour} Theme editing is disabled in the wp-config"
echo -e "${green}[*]:${nocolour} Core auto update is enabled in the wp-config"
echo ""
echo -e "${orange}Laravel notes: ${nocolour}"
echo -e "${green}[*]:${nocolour} Read the Corcel documentation at https://packagist.org/packages/jgrossi/corcel"
echo -e "${green}[*]:${nocolour} to use the artisan command wp:generate-keys, add ${orange}\App\Console\Commands\WpGenerateKeys::class${nocolour} to the \$commands array in ${orange}${project_dir}/app/Console/Kernel.php${nocolour}"
echo -e "${green}[*]:${nocolour} to use the debugbar, follow the instructions at ${orange}https://github.com/barryvdh/laravel-debugbar/blob/master/readme.md${nocolour}"
echo -e "${green}[*]:${nocolour} Add:"
echo -e "${orange}} 	    $this->app->singleton(Wildcache::class, function ( $app ) {"
echo -e " 		    return new Wildcache();"
echo -e " 	    });${nocolour}"
echo -e "AppServiceProvider.php, follow the instructions at ${orange}https://github.com/barryvdh/laravel-debugbar/blob/master/readme.md${nocolour}"


