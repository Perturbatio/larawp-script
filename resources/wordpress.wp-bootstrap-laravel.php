<?php
require_once __DIR__ . '/../bootstrap/autoload.php';
require_once __DIR__ . '/../bootstrap/app.php';

use Illuminate\Support\Facades\Facade;


$laravel_app    = app();
$laravel_kernel = $laravel_app->make( 'Illuminate\Contracts\Http\Kernel' );

$laravel_request = Illuminate\Http\Request::capture();

$laravel_kernel->getApplication()->instance( 'request', $laravel_request );

$laravel_kernel->bootstrap();

//Facade::clearResolvedInstance( 'request' );
