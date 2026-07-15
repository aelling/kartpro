<?php

namespace Drupal\hs_subscribe\EventSubscriber;

use Drupal\Component\Datetime\TimeInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * Creates a Commerce Recurring subscription for each flagged order item when an
 * order is placed. (Recurring billing itself runs once a recurring-capable
 * payment gateway is configured.)
 */
class SubscribeOrderSubscriber implements EventSubscriberInterface {

  /**
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * @var \Drupal\Component\Datetime\TimeInterface
   */
  protected $time;

  public function __construct(EntityTypeManagerInterface $entity_type_manager, TimeInterface $time) {
    $this->entityTypeManager = $entity_type_manager;
    $this->time = $time;
  }

  /**
   * {@inheritdoc}
   */
  public static function getSubscribedEvents() {
    return [
      'commerce_order.place.post_transition' => 'onPlace',
    ];
  }

  /**
   * Creates subscriptions for subscribe-flagged order items.
   */
  public function onPlace($event) {
    $order = $event->getEntity();
    // Only create subscriptions if a billing schedule exists.
    $schedule = $this->entityTypeManager->getStorage('commerce_billing_schedule')->load('every_4_weeks');
    if (!$schedule) {
      return;
    }
    $storage = $this->entityTypeManager->getStorage('commerce_subscription');

    foreach ($order->getItems() as $order_item) {
      if (!$order_item->getData('hs_subscribe')) {
        continue;
      }
      $variation = $order_item->getPurchasedEntity();
      if (!$variation) {
        continue;
      }
      // Recurring price = the discounted unit price (85%).
      $unit_price = $order_item->getUnitPrice();
      $recurring_price = $unit_price ? $unit_price->multiply('0.85') : NULL;

      $subscription = $storage->create([
        'type' => 'product_variation',
        'store_id' => $order->getStoreId(),
        'billing_schedule' => 'every_4_weeks',
        'uid' => $order->getCustomerId(),
        'purchased_entity' => $variation->id(),
        'title' => $order_item->getTitle(),
        'quantity' => $order_item->getQuantity(),
        'unit_price' => $recurring_price ?: $unit_price,
        'state' => 'active',
        'starts' => $this->time->getRequestTime(),
        'initial_order' => $order->id(),
      ]);
      $subscription->save();
    }
  }

}
