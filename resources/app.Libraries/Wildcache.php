<?php
namespace App\Libraries;

use \Cache;
use Illuminate\Support\Collection;
use Illuminate\Support\Traits\Macroable;

/**
 * Created by kris with PhpStorm.
 * User: kris
 * Date: 05/11/16
 * Time: 00:31
 */

/**
 * Class Wildcache
 * @package App\Libraries
 */
class Wildcache {

	use Macroable;

	/**
	 * @var string
	 */
	public $cacheKey = '__' . __CLASS__ . '.map';

	/**
	 * @var array
	 */
	public $map;

	/**
	 * Wildcache constructor.
	 */
	public function __construct() {
		$this->map = $this->loadMap();
	}

	/**
	 * @param $key
	 *
	 * @return bool
	 */
	public function forget( $key ) {
		$result = false;
		if ($key === $this->cacheKey) {
			return false;
		}

		$items = $this->findItems($key);
		if ($items->count() > 0) {
			$items->each(function ( $item ) {
				app('cache')->forget($item);
			});

			$result = true;
			$this->removeKey($key);
		}


		return $result;
	}

	/**
	 * @param $key
	 *
	 * @return bool
	 */
	public function get( $key ) {
		$result = [];
		if ($key === $this->cacheKey) {
			return false;
		}

		$items = $this->findItems($key);

		if ($items->count() > 0) {
			$result = $items->reduce(function ( $result, $item ) {
				$result[ $item ] = app('cache')->get($item);

				return $result;
			}, []);
		}


		return collect($result);
	}

	/**
	 * @return mixed
	 */
	public function loadMap() {
		return app('cache')->get($this->cacheKey);
	}

	/**
	 * @return mixed
	 */
	public function writeMap() {
		return app('cache')->forever($this->cacheKey, $this->map);
	}

	/**
	 * Purge (clear) the entire map
	 * @return mixed
	 */
	public function purgeMap() {
		return app('cache')->forget($this->cacheKey);
	}

	/**
	 * @param $key
	 * @param $tags
	 *
	 * @return mixed
	 */
	public function handleForgotten( $key, $tags ) {
		if ($key === $this->cacheKey) {
			return false;
		}

		array_forget($this->map, $key);

		$parts = explode('.', $key);

		//clear as far up the tree as we can
		$canExit = false;
		while ( !$canExit) {
			$partKey = implode('.', $parts);
			//as long as there's only one item in the current path, we're safe to purge it
			if (count(array_get($this->map, $partKey)) < 2) {
				array_forget($this->map, $partKey);
				array_pop($parts);
			} else {
				$canExit = true;
			}

			if ( empty($parts) ) {
				$canExit = true;
			}
		}

		return $this->writeMap();
	}

	/**
	 * @param $key
	 * @param $tags
	 * @param $value
	 * @param $minutes
	 *
	 * @return mixed
	 */
	public function handleWritten( $key, $tags, $value, $minutes ) {
		if ($key === $this->cacheKey) {
			return false;
		}
		array_set($this->map, $key, $key);

		return $this->writeMap();
	}

	/**
	 * @param $key
	 *
	 * @return Collection
	 */
	protected function findItems( $key ) {
		$key = rtrim($key, '.*');//trim trailing .* so that if the user writes cache.items.* all cache.items will be affected in the same way as writing cache.items
		return collect(array_get($this->map, $key))->flatten();
	}

	/**
	 * @param $key
	 *
	 * @return mixed
	 */
	protected function removeKey( $key ) {
		array_set($this->map, $key, null);
		return $this->writeMap();
	}
}
