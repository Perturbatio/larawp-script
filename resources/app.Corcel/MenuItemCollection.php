<?php
namespace App\Corcel;

/**
 * Created by kris with PhpStorm.
 * User: kris
 * Date: 22/10/16
 * Time: 19:08
 */
use Illuminate\Support\Collection;

/**
 * Class MenuItemCollection
 * @package App\Corcel
 */
class MenuItemCollection extends Collection {

	/**
	 * Convert to a nested MenuItemCollection
	 *
	 * @param int $maxDepth
	 * @param int $currentDepth
	 * @param int $lastItemId
	 *
	 * @return static
	 */
	public function toNested( $maxDepth = 0, $currentDepth = 0, $lastItemId = 0 ) {

		$result = new static();

		foreach ($this->items as $item) {
			if ($item->parent_id === $lastItemId) {
				$canRecurse = ($maxDepth === 0) || ($currentDepth < $maxDepth);

				if ($canRecurse) {

					$item->children = $this->toNested($maxDepth, $currentDepth + 1, $item->ID);
				} else {
					$item->children = new static();//ensure children has the same methods regardless of whether it's empty
				}

				$item->depth = $currentDepth;
				$result->push($item);

			}

		}

		return $result;
	}

	/**
	 * @param callable $callback
	 * @param int      $currentDepth
	 * @param int      $lastDepth
	 */
	public function walk( callable $callback, $currentDepth = 0, $lastDepth = -1 ) {

		$index = 0;
		$count = count($this->items);

		foreach ($this->items as $key => $item) {
			$callback($item, $index, $count, $currentDepth, $lastDepth);
			$lastDepth = $currentDepth;
			if (isset($item->children) && $item->children->count() > 0) {
				$item->children->walk($callback, $currentDepth + 1, $lastDepth);
			}
			$index++;
		}

	}

}
