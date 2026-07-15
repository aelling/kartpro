<?php

namespace Drupal\hs_rewards\EventSubscriber;

use Drupal\user\UserDataInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * Awards Honey Points (1 pt / $1) when an order is placed.
 */
class OrderPointsSubscriber implements EventSubscriberInterface {

  /**
   * The user data service.
   *
   * @var \Drupal\user\UserDataInterface
   */
  protected $userData;

  public function __construct(UserDataInterface $user_data) {
    $this->userData = $user_data;
  }

  /**
   * {@inheritdoc}
   */
  public static function getSubscribedEvents() {
    return [
      'commerce_order.place.post_transition' => 'onOrderPlace',
    ];
  }

  /**
   * Adds points to the customer's balance on order placement.
   */
  public function onOrderPlace($event) {
    $order = $event->getEntity();
    $uid = $order->getCustomerId();
    if (!$uid) {
      return;
    }
    $total = $order->getTotalPrice();
    if (!$total) {
      return;
    }
    $points = (int) floor((float) $total->getNumber());
    $current = (int) $this->userData->get('hs_rewards', $uid, 'points');
    $this->userData->set('hs_rewards', $uid, 'points', $current + $points);
  }

}
