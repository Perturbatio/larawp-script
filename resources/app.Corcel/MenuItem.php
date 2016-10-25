<?php namespace App\Corcel;

/**
 * Created by kris with PhpStorm.
 * User: kris
 * Date: 22/10/16
 * Time: 15:28
 */
class MenuItem extends Post {

	protected $postType = 'nav_menu_item';

	protected $with = ['meta', 'object'];

	/**
	 * @return string
	 */
	public function getTitleAttribute() {
		$title = parent::getTitleAttribute();
		if ( empty( $title ) ) {
			if ($this->objectType !== 'custom') {
				$title = $this->object->title;
			}
		}

		return $title;
	}

	/**
	 * @return int
	 */
	public function getParentIdAttribute() {
		return (int)$this->meta->where('meta_key', '_menu_item_menu_item_parent')->first()->value;
	}

	/**
	 * @return string
	 */
	public function getUrlAttribute() {
		\Wordpress::init();
		return get_permalink($this->object->ID);
	}

	/**
	 * @return \Illuminate\Database\Eloquent\Relations\MorphTo
	 */
	public function object() {
		return $this->morphTo();
	}

	/**
	 * @return string
	 */
	public function getObjectTypeAttribute() {
		return (string) $this->meta->_menu_item_object;
	}

	/**
	 * @param $type
	 */
	public function setObjectTypeAttribute( $type ) {
		$this->meta->_menu_item_object = $type;
	}


	/**
	 * @return string
	 */
	public function getObjectIdAttribute() {
		return (string) $this->meta->_menu_item_object_id;
	}

	/**
	 * @param $type
	 */
	public function setObjectIdAttribute( $type ) {
		$this->meta->_menu_item_object_id = $type;
	}


	/**
	 * @return string
	 */
	public function getMenuItemTypeAttribute() {
		return (string) $this->meta->_menu_item_type;
	}

	/**
	 * @param $type
	 *
	 */
	public function setMenuItemTypeAttribute( $type ) {
		$this->meta->_menu_item_type = $type;
	}


	/**
	 * @return array
	 */
	public function getClassesAttribute() {
		return (array) $this->meta->_menu_item_classes;
	}

	/**
	 * @param $classes
	 *
	 */
	public function setClassesAttribute( $classes ) {
		$this->meta->_menu_item_classes = (array) $classes;
	}

	/**
	 * @return bool
	 */
	public function hasChildren(){
		return isset($this->children) && $this->children->count() > 0;
	}

}
