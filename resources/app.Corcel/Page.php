<?php namespace App\Corcel;

/**
 * Class Page
 * @package App\Corcel
 */
class Page extends Post {
	protected $postType = 'page';

	public function menuItems() {
		return $this->morphMany('App\Corcel\MenuItem', 'object', 'page');
	}
}
