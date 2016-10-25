<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Database\Eloquent\Relations\Relation;

class CorcelServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap the application services.
     *
     * @return void
     */
    public function boot()
    {
        //

	    Relation::morphMap([
		    'post'  => \App\Corcel\Post::class,
		    'page' => \App\Corcel\Page::class,
		    'custom' => \App\Corcel\CustomMenuObject::class,
		    'category' => \App\Corcel\Category::class,
	    ]);
    }

    /**
     * Register the application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }
}
