<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class WpGenerateKeys extends Command {
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'wp:generate-keys {keyname?} {--show : Display the key instead of modifying files} {--with-config-key : Used in conjunction with --show to display the laravel config item key name}';

    /**
     * The console command description.
     *
     * @var string
     */
    //protected $description = "(re)generate the wordpress keys in the .env file" . PHP_EOL . " \033[0;31mWARNING: if you do this once the wordpress database has been set up, you will invalidate all logins and any encrypted values.\033[0m";

    protected static $keys = [
        "key"            => 'WP_AUTH_KEY',
        "secure_key"     => "WP_AUTH_SECURE_KEY",
        "logged_in_key"  => "WP_AUTH_LOGGED_IN_KEY",
        "nonce_key"      => "WP_AUTH_NONCE_KEY",
        "salt"           => "WP_AUTH_SALT",
        "secure_salt"    => "WP_AUTH_SECURE_SALT",
        "logged_in_salt" => "WP_AUTH_LOGGED_IN_SALT",
        "nonce_salt"     => "WP_AUTH_NONCE_SALT",
    ];

    static $shellColours = [
        "RED"    => "\033[0;31m",
        "GREEN"  => "\033[1;32m",
        "ORANGE" => "\033[0;33m",
        "NORMAL" => "\033[0m",
    ];

    /**
     * Create a new command instance.
     *
     */
    public function __construct() {
        parent::__construct();
        $description = "(re)generate the wordpress keys in the .env file" . PHP_EOL . PHP_EOL;
        $description .= static::$shellColours['ORANGE'] . "Keys available:" . static::$shellColours['NORMAL'] . PHP_EOL;

        foreach ((array) static::$keys as $configKey => $envKey) {
            $description .= 'wordpress.auth.' . static::$shellColours['GREEN'] . "{$configKey}:" . static::$shellColours['NORMAL'] . " {$envKey}" . PHP_EOL;
        }
        $description .= PHP_EOL . "\033[0;31mWARNING: if you do this once the wordpress database has been set up, 
         you will invalidate all logins and any encrypted values.\033[0m" . PHP_EOL;
        $this->setDescription($description);
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle() {

        $keyname = $this->argument('keyname');

        list($showingKey, $showConfigKey) = $this->getCommandOptions();

        //if the user has passed in a single key, handle that and return
        if ( ! empty($keyname)) {
            return $this->handleKey($keyname, $showingKey, $showConfigKey);
        }

        //otherwise set all
        foreach (static::$keys as $index => $keyname) {

            $result = $this->handleKey($index, $showingKey, $showConfigKey);
            if ($result === false) {
                $this->error("Is there a value for {$keyname} in the .env?");
            } else {
                echo $result;
            }
        }

        return true;

    }

    /**
     * @param $key
     *
     * @return mixed
     */
    public function getConfigValue( $key ) {
        return $this->laravel['config'][ 'wordpress.auth.' . $key ];
    }

    /**
     * Set the wordpress key in the environment file.
     *
     * @param  string $key
     *
     * @return Boolean
     */
    protected function setEnvironmentFileValue( $key, $search, $replace ) {
        $haystack      = file_get_contents($this->laravel->environmentFilePath());
        $replaceResult = str_replace(
            "{$key}=" . $search,
            "{$key}=" . $replace,
            $haystack);

        $result = file_put_contents($this->laravel->environmentFilePath(), $replaceResult);

        return ($haystack !== $replaceResult);
    }

    /**
     * Generate a random key for the application.
     *
     * @return string
     */
    protected function generateRandomKey() {
        return 'base64:' . base64_encode(random_bytes(
            $this->laravel['config']['app.cipher'] == 'AES-128-CBC' ? 16 : 32
        ));
    }

    /**
     * @param      $configKey
     * @param bool $showingKey
     * @param bool $showingConfigKey
     *
     * @return string
     */
    protected function handleKey( $configKey, $showingKey = false, $showingConfigKey = false ) {
        $envKey = static::$keys[ $configKey ];
        if ( ! $showingKey) {
            $setResult = $this->setEnvironmentFileValue($envKey, $this->getConfigValue($configKey), $this->generateRandomKey());

            if ($setResult !== false && $setResult > 0) {
                return $this->info("Wordpress key [$envKey] set successfully.");
            } else {
                return $this->error("Error setting {$envKey}");
            }
        } else {
            return (($showingConfigKey) ? PHP_EOL . "(wordpress.auth." . $configKey . ")" . PHP_EOL : '') . $envKey . '=' . $this->getConfigValue($configKey) . PHP_EOL;
        }
    }

    /**
     * @return array
     */
    protected function getCommandOptions() {
        $showingKey = false;
        if ($this->option('show')) {
            $showingKey = true;
        }

        $showConfigKey = false;
        if ($this->option('with-config-key')) {
            $showConfigKey = true;

        }

        return array($showingKey, $showConfigKey);
    }
}
