<?php namespace App\Http\Controllers;

use App\Libraries\Wordpress;

class CatchallController extends Controller {

	public function index( $request = null ) {
		return Wordpress::handleRoute();
	}

}
