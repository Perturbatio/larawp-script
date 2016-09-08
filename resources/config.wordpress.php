<?php
/**
 * A config file for wordpress related config items
 *
 * @version    1.0.0
 * @see        wp-config.php
 */
return array(
	'use_themes' => false,
	'database'   => [
		'name'     => env( 'DB_DATABASE', '' ),
		'user'     => env( 'DB_USERNAME', '' ),
		'password' => env( 'DB_PASSWORD', '' ),
		'host'     => env( 'DB_HOST', 'localhost' ),
	],
	'auth'       => [
		'key'            => env( 'WP_AUTH_KEY', '' ),
		'secure_key'     => env( 'WP_AUTH_SECURE_KEY', '' ),
		'logged_in_key'  => env( 'WP_AUTH_LOGGED_IN_KEY', '' ),
		'nonce_key'      => env( 'WP_AUTH_NONCE_KEY', '' ),
		'salt'           => env( 'WP_AUTH_SALT', '' ),
		'secure_salt'    => env( 'WP_AUTH_SECURE_SALT', '' ),
		'logged_in_salt' => env( 'WP_AUTH_LOGGED_IN_SALT', '' ),
		'nonce_salt'     => env( 'WP_AUTH_NONCE_SALT', '' ),
	],
);
