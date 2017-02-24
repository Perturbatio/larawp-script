<?php
namespace App\Libraries;

use \Cache;
use Illuminate\Support\Traits\Macroable;

/**
 * Created by Kris Kelly
 * Date: 21/07/15
 * Time: 13:38
 * @modified 10/09/2016
 */

/**
 * Class Wordpress
 * @package App\Libraries
 */
class Wordpress {

	use Macroable;

	/**
	 *
	 * @param int $code = 404
	 *
	 * @return string
	 */
	public static function abort( $code = 404 ) {
		static::init();
		ob_start();
		global $wp_query;
		$wp_query->is_404    = ( $code == 404 );
		$wp_query->is_single = false;
		$wp_query->is_page   = false;

		include( get_query_template( $code ) );

		return ob_get_clean();
	}

	/**
	 * Override the current page title
	 * This is useful if you want to set a page title for a laravel route when using a wp template
	 *
	 * @param     $title
	 * @param int $priority
	 */
	public static function setPageTitle( $title, $priority = 100 ) {
		if ( function_exists( 'add_filter' ) ) {
			add_filter( 'wp_title', function ( $data ) use ( $title ) {
				// $data should contain the current post title
				return $title;
			}, $priority, 2 );
		}
	}

	/**
	 *
	 * Loads the wp headers and creates the global vars (bleah!)
	 *
	 * Note: If you want to use any wordpress related functions in your laravel code
	 * you should invoke `Wordpress::init()` beforehand.
	 *
	 * Uses a static var to prevent repeated called from doing anything
	 *
	 * @static $wp_init_called
	 */
	public static function init() {
		static $wp_init_called = false;
		if ( ! $wp_init_called ) {
			$debug_enabled = config( 'app.debug', false );
			if ( $debug_enabled && function_exists( 'start_measure' ) ) {
				start_measure( 'wp_render', 'Wordpress' );
			}
			/*
			 *--------------------------------------------------------------------------
			 * Wordpress
			 *--------------------------------------------------------------------------
			 *
			 * Load the wordpress initialization script
			 *
			 */

			if ( $debug_enabled ) {
				// disable mySQL Session Cache
				if ( ! defined( 'QUERY_CACHE_TYPE_OFF' ) ) {
					define( 'QUERY_CACHE_TYPE_OFF', true );
				}
				if ( ! defined( 'SAVEQUERIES' ) ) {
					define( 'SAVEQUERIES', true );
				}
			}

			define( 'WP_USE_THEMES', config( 'wordpress.use_themes', true ) );

			require_once base_path() . '/wordpress/wp-blog-header.php';
			$defined_vars = get_defined_vars();

			/**
			 * push vars defined in global scope within wordpress into the $GLOBALS array
			 * but only if they're not already defined
			 */
			foreach ( $defined_vars as $global_key => $global_value ) {
				if ( ! isset( $GLOBALS[ $global_key ] ) ) {
					$GLOBALS[ $global_key ] = $global_value;
				}
			}
		} else {
			$wp_init_called = true;
		}

	}

	/**
	 * @return string
	 *
	 */
	public static function handleRoute( $route = '' ) {

		static::init();

		$debug_enabled = config( 'app.debug', false );
		$template      = self::getRouteTemplate( $route );
		$result        = self::renderTemplate( $template, compact( $debug_enabled ) );

		if ( $debug_enabled && function_exists( 'stop_measure' ) ) {
			stop_measure( 'wp_render' );

			// disable mySQL Session Cache
			if ( ! defined( 'QUERY_CACHE_TYPE_OFF' ) ) {
				define( 'QUERY_CACHE_TYPE_OFF', true );
			}

			if ( ! defined( 'SAVEQUERIES' ) ) {
				define( 'SAVEQUERIES', true );
			}

			$app      = app();
			$debugBar = $app['debugbar'];


			if ( $debugBar->hasCollector( 'queries' ) ) {
				global $wp_query;

				$db         = $app['db'];
				$connection = $db->connection( config( 'database.default' ) );

				/**
				 * @var $queryCollector \Barryvdh\Debugbar\DataCollector\QueryCollector
				 */
				$queryCollector = $debugBar->getCollector( 'queries' );

				$debugBar->addMessage( $wp_query, 'wp_query_object' );

				foreach ( static::getQueries() as $query ) {

					$queryCollector->addQuery( (string) $query['sql'], [], $query['time'] * 1000, $connection );
				}

				$debugBar->collect();

			}

		}

		return $result;
	}

	/**
	 * @param $template_name
	 *
	 * @return string
	 */
	public static function renderTemplate( $template_name, $params = [] ) {
		$debug_enabled = config( 'app.debug', false );

		if ( $debug_enabled && function_exists( 'stop_measure' ) ){
			$app      = app();
			$debugBar = $app[ 'debugbar' ];
			$debugBar->addMessage( $template_name, 'Wordpress::renderTemplate' );
		}

		static::init();
		$Wordpress__template_to_render = self::locateTemplate( $template_name );

		/**
		 * Filter the path of the current template before including it.
		 *
		 * @since 3.0.0
		 *
		 * @param string $Wordpress__template_to_render The path of the template to include.
		 */
		if ( $Wordpress__template_to_render = apply_filters( 'template_include', $Wordpress__template_to_render ) ) {
			ob_start();
			extract( $params );
			include( $Wordpress__template_to_render );

			return ob_get_clean();

		} else {
			return static::abort();
		}

	}

	/**
	 * @return array
	 */
	public static function getQueries() {
		global $wpdb;

		$result = [];

		// disabled session cache of mySQL
		if ( QUERY_CACHE_TYPE_OFF ) {
			$wpdb->query( 'SET SESSION query_cache_type = 0;' );
		}

		if ( $wpdb->queries ) {

			foreach ( $wpdb->queries as $query ) {

				$query[0] = trim( preg_replace( '/[[:space:]]+/', ' ', $query[0] ) );

				$result[] = array(
					'sql'    => $query[0],
					'time'   => $query[1],
					'source' => $query[2],
				);

			}
		}


		return $result;
	}

	/**
	 * @param $post
	 */
	public static function forcePost( $post ) {
		global $wp_query;
		$wp_query->posts[]    = $post;
		$wp_query->post_count = 1;

		$wp_query->is_404    = false;
		$wp_query->is_single = false;
		$wp_query->is_page   = true;

		$GLOBALS['post'] = $post;
	}

	/**
	 * @return string|void
	 */
	public static function getCurrentUrl() {
		static::init();
		global $wp;

		return home_url( add_query_arg( array(), $wp->request ) );
	}

	/**
	 * @return null|Post
	 */
	public static function getCurrentPost() {

		$currentPostId = get_the_ID();
		if ( ! empty( $currentPostId ) ) {
			return get_post( $currentPostId );
		}

		return null;
	}

	/**
	 * @param $route
	 *
	 * @return string
	 */
	protected static function getRouteTemplate( $route ) {
		if ( is_404() && $template = get_404_template() ) {

		} elseif ( is_search() && $template = get_search_template() ) {

		} elseif ( is_front_page() && $template = get_front_page_template() ) {
		} elseif ( is_home() && $template = get_home_template() ) {
		} elseif ( is_post_type_archive() && $template = get_post_type_archive_template() ) {
		} elseif ( is_tax() && $template = get_taxonomy_template() ) {
		} elseif ( is_attachment( $route ) && $template = get_attachment_template() ) {
			remove_filter( 'the_content', 'prepend_attachment' );
		} elseif ( is_single( $route ) && $template = get_single_template() ) {
		} elseif ( is_page( $route ) && $template = get_page_template() ) {
		} elseif ( is_category() && $template = get_category_template() ) {
		} elseif ( is_tag() && $template = get_tag_template() ) {
		} elseif ( is_author() && $template = get_author_template() ) {
		} elseif ( is_date() && $template = get_date_template() ) {
		} elseif ( is_archive() && $template = get_archive_template() ) {
		} elseif ( is_comments_popup() && $template = get_comments_popup_template() ) {
		} elseif ( is_paged() && $template = get_paged_template() ) {
		} else {
			$template = get_index_template();

		}
		$debug_enabled = config( 'app.debug', false );

		if ( $debug_enabled && function_exists( 'stop_measure' ) ){
			$app      = app();
			$debugBar = $app[ 'debugbar' ];
			$debugBar->addMessage( $template, 'template' );
		}
		return $template;
	}

	/**
	 * @param $template_name
	 *
	 * @return string
	 */
	protected static function locateTemplate( $template_name ) {
		return Cache::remember( 'wordpress.template.' . md5( $template_name ), 5, function () use ( $template_name ) {
			$template_path = realpath( $template_name );

			//----------------[ If the template path doesn't exist within the WP TEMPLATEPATH location ]----------------//
			if ( ! starts_with( $template_path, TEMPLATEPATH ) || ! file_exists( $template_name ) ) {
				$Wordpress__template_to_render = get_query_template( 'page', [ $template_name ] );

				return $Wordpress__template_to_render;
			} else {
				$Wordpress__template_to_render = $template_name;

				return $Wordpress__template_to_render;
			}
		} );
	}
}
