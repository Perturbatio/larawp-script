<?php namespace App\Corcel;

use Corcel\Post as CorcelPost;

/**
 * Class Post
 * an extension of Corcel\Post
 * @package App
 */
class Post extends CorcelPost {
	public function menuItems(){
		return $this->morphMany('App\Corcel\MenuItem', 'object', 'post');
	}
}
