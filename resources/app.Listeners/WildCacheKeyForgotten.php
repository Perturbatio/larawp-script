<?php

namespace App\Listeners;

use Illuminate\Cache\Events\KeyForgotten;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;

class WildCacheKeyForgotten
{
	/**
	 * Create the event listener.
	 *
	 */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param  KeyForgotten  $event
     * @return void
     */
    public function handle(KeyForgotten $event)
    {
        app('Wildcache')->handleForgotten($event->key, $event->tags);
    }
}
