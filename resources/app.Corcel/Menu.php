<?php namespace App\Corcel;

use Corcel\Menu as CorcelMenu;

/**
 * Class Menu
 * @package App\Corcel
 */
class Menu extends CorcelMenu
{
	protected $with = ['term', 'menuItems'];

	public function nameAttribute() {
		return $this->term->name;
	}

	/**
	 * Return a QueryBuilder instance where the menu slug is equal to the specified parameter
	 *
	 * @param $slug
	 *
	 * @return \Illuminate\Database\Eloquent\Builder|static
	 */
	static public function whereSlug($slug){

		return static::with([
				'term' => function ( $query ) use ($slug){
					$query->where('slug', $slug);
				}
			]);
	}

	/**
	 * Return a QueryBuilder instance where the menu name is equal to the specified parameter
	 *
	 * @param $name
	 *
	 * @return \Illuminate\Database\Eloquent\Builder|static
	 */
	static public function whereName($name){

		return static::with([
				'term' => function ( $query ) use ($name){
					$query->where('name', $name);
				}
			]);
	}

	/**
	 * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
	 */
	public function nav_items() {
		return $this->menuItems();
	}

	/**
	 * Relationship with Posts model
	 * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
	 */
	public function menuItems() {
		return $this->belongsToMany('MenuItem', 'term_relationships', 'term_taxonomy_id', 'object_id')->orderBy('menu_order');
	}

	public function getMenuItemsAttribute(){
		return new MenuItemCollection($this->menuItems()->get());
	}

}
