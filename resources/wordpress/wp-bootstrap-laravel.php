<?php
require_once __DIR__ . '/../wordpress/wp-includes/l10n.php';//workaround for the __ translation function conflicting with laravel's
require_once __DIR__ . '/../bootstrap/autoload.php';
require_once __DIR__ . '/../bootstrap/app.php';

$laravel_app    = app();
$laravel_kernel = $laravel_app->make( 'Illuminate\Contracts\Http\Kernel' );

$laravel_request = Illuminate\Http\Request::capture();

$laravel_kernel->getApplication()->instance( 'request', $laravel_request );

$laravel_kernel->bootstrap();
