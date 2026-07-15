<?php

namespace Drupal\hs_account\Theme;

use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Theme\ThemeNegotiatorInterface;

/**
 * Forces the site's default (front-end) theme on customer account pages.
 *
 * By default Drupal renders /user/{uid}/edit in the admin theme for privileged
 * users, which breaks the branded account area. This negotiator wins (high
 * priority) for the account routes and returns the default theme instead.
 */
class AccountThemeNegotiator implements ThemeNegotiatorInterface {

  /**
   * The config factory.
   *
   * @var \Drupal\Core\Config\ConfigFactoryInterface
   */
  protected $configFactory;

  public function __construct(ConfigFactoryInterface $config_factory) {
    $this->configFactory = $config_factory;
  }

  /**
   * {@inheritdoc}
   */
  public function applies(RouteMatchInterface $route_match) {
    $account_routes = [
      'entity.user.canonical',
      'entity.user.edit_form',
    ];
    return in_array($route_match->getRouteName(), $account_routes, TRUE);
  }

  /**
   * {@inheritdoc}
   */
  public function determineActiveTheme(RouteMatchInterface $route_match) {
    return $this->configFactory->get('system.theme')->get('default') ?: 'hivesticks';
  }

}
