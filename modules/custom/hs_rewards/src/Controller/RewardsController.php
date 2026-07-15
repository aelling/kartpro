<?php

namespace Drupal\hs_rewards\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\user\UserInterface;

/**
 * Renders the Honey Points rewards page in the account area.
 */
class RewardsController extends ControllerBase {

  /**
   * Tiers: name => minimum points.
   */
  const TIERS = [
    ['name' => 'Worker Bee', 'min' => 0],
    ['name' => 'Forager', 'min' => 750],
    ['name' => 'Keeper', 'min' => 2000],
  ];

  /**
   * Builds the rewards page for a user.
   */
  public function view(UserInterface $user) {
    $points = (int) \Drupal::service('user.data')->get('hs_rewards', $user->id(), 'points');

    $tier = self::TIERS[0];
    $next = NULL;
    foreach (self::TIERS as $i => $t) {
      if ($points >= $t['min']) {
        $tier = $t;
        $next = self::TIERS[$i + 1] ?? NULL;
      }
    }
    $to_next = $next ? max(0, $next['min'] - $points) : 0;
    $span = $next ? max(1, $next['min'] - $tier['min']) : 1;
    $pct = $next ? min(100, (int) round(($points - $tier['min']) / $span * 100)) : 100;
    $perk = $next
      ? $this->t('@n pts to unlock @tier', ['@n' => $to_next, '@tier' => $next['name']])
      : $this->t('You’ve reached the top tier — enjoy the perks!');

    $referral = strtoupper(preg_replace('/[^a-z0-9]/i', '', $user->getAccountName())) . '-HIVE';

    return [
      '#theme' => 'hs_rewards_page',
      '#points' => $points,
      '#tier' => $tier['name'],
      '#next_tier' => $next['name'] ?? '',
      '#to_next' => $to_next,
      '#pct' => $pct,
      '#perk' => $perk,
      '#referral' => $referral,
      '#uid' => $user->id(),
      '#attached' => ['library' => ['hivesticks/account']],
      '#cache' => ['max-age' => 0],
    ];
  }

}
