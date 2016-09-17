# larawp-script
A simple bash script to set up laravel and wordpress and provides a few helpers to make integrating 
wordpress and laravel a little easier.

It will do the following:

1. Create a laravel project folder `<project_name>`
2. Install jgrossi/corcel
3. Install laravelcollective/html
4. Install barryvdh/laravel-debugbar 
5. Install wordpress
6. Patch the wp-config file to use laravel config items 
7. Patch wp-config and add a bootstrap include which will allow you to use Laravel features in your WP themes/plugins
8. Add a wordpress config file to `<project_name>/config/wordpress.php` which is referenced by wp-config.php
9. Patch the Laravel index to prevent WP overwriting its $response global var
10. Provide a CatchallController to intercept calls to any route not defined in routes/web.php
11. Adds a catchall route for said controller
12. Provide a helper class to make dealing with wordpress a little easier (in app/Libraries/Wordpress.php)
13. Provides a sample apache config to allow wordpress to be served from below the public dir. (apache-additions.conf) 

Usage: `sh larawp.sh <project_name> [-c|--use-composer]`

If you would like to have the command usable from anywhere, you can symlink to it:

`ln -s /path/to/larawp.sh /usr/local/bin/larawp`

This will allow you to use `larawp <project_name>`.

By default, the script will use the `laravel` command to install, but if there is an issue with this 
(i.e. command missing or remote download server unavailable), use `-c` or `--use-composer` to use 
`composer create-project` instead.

Once installed:

Next Steps: 

1. You now need to modify the server config to point the wordpress URLs to below the document root
an example config for apache is located at `larawp/resources/apache-additions.conf`
2. Modify the `.env` file to set database settings (used in `config/wordpress.php`) and `wp-config.php`
3. Set up the wordpress site via the web interface

Wordpress notes: 

* Remember to not make the admin username `admin` (common hack target)
* Theme editing is disabled in the `wp-config`
* Core auto update is enabled in the `wp-config`

Laravel notes: 

* Read the Corcel documentation at `https://packagist.org/packages/jgrossi/corcel`
* to use the artisan command `wp:generate-keys`, add `\App\Console\Commands\WPGenerateKeys::class` to the $commands array in `app/Console/Kernel.php`
