<?php
namespace App\Corcel;

	/**
	 * Created by kris with PhpStorm.
	 * User: kris
	 * Date: 22/10/16
	 * Time: 16:24
	 */
use Corcel\Model as CorcelModel;
use Corcel\Model;
use \Corcel\PostBuilder;
use Illuminate\Database\Eloquent\Builder as QueryBuilder;

/**
 * Class CustomMenuObject
 * @package App\Corcel
 */
class CustomMenuObject extends MenuItem  {

	protected $fillable = ['url', 'title'];

	/**
	 * @return string
	 */
	public function getUrlAttribute(){

		return $this->meta->reduce(function( $value = '', $meta){

			if ($meta->meta_key === '_menu_item_url'){
				return $meta->value;
			}
			return $value;
		});
	}
}
