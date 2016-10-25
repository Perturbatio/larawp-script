<?php
namespace App\Corcel;

	/**
	 * Created by kris with PhpStorm.
	 * User: kris
	 * Date: 22/10/16
	 * Time: 17:04
	 */
use Corcel\TermTaxonomyBuilder;

/**
 * Class Category
 * @package App\Corcel
 */
class Category extends TermTaxonomy {
	/**
	 * Used to set the post's type
	 */
	protected $taxonomy = 'category';

	public function menuItems() {
		return $this->morphMany('App\Corcel\MenuItem', 'object', 'category');
	}

	//select * from `wp_term_taxonomy` where `taxonomy` = 'category' and `wp_term_taxonomy`.`term_taxonomy_id` in (1)
	/**
	 * Overriding newQuery() to the custom TermTaxonomyBuilder with some interesting methods
	 *
	 * @param bool $excludeDeleted
	 *
	 * @return \Corcel\TermTaxonomyBuilder
	 */
	public function newQuery( $excludeDeleted = true ) {
		$builder = new TermTaxonomyBuilder($this->newBaseQueryBuilder());
		$builder->setModel($this)->with($this->with);

		if (isset($this->taxonomy) and ! empty($this->taxonomy) and ! is_null($this->taxonomy)) {
			$builder->where('taxonomy', $this->taxonomy);
		}

		return $builder;
	}

}
