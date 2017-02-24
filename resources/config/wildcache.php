<?php
/**
 * Created by kris with PhpStorm.
 * User: kris
 * Date: 24/02/17
 * Time: 01:46
 */
return array(
	'cache' => [
		'time'               => [
			'short'  => env('CACHE_TIME_SHORT', 1),
			'medium' => env('CACHE_TIME_MEDIUM', 30),
			'long'   => env('CACHE_TIME_LONG', 60),
		],
		/**
		 * clear specific cache items when a post of the specified type is saved wildcards can be used like
		 * product.{post_id} where post_id will be replaced with the particular post's id
		 *
		 * if you want to clear all product caches, you can use 'product' which
		 * will clear all items that are 'product' or begin with 'product.'
		 */
		'clear_on_post_save' => [ //array of post_type=>[cache item array]
			'event'   => [
			  'events.most-important',
			],
			'product' => [
			  'home.featured-articles',
			  'product.{post_id}',
			  'products.published',
			],
			'staff'   => [
			  'staff.{post_id}',
			],
			//------------------[ any post type ]------------------//

			'*' => [
			  'Wordpress.resolvePost.{post_id}',
			  'markup.article-summary.{post_id}',
			],
		],
	],
);
