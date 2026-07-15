<?php

namespace Drupal\hs_subscribe;

use Drupal\commerce_cart\OrderItemMatcherInterface;
use Drupal\commerce_order\Entity\OrderItemInterface;

/**
 * Decorates the order item matcher so a "subscribe" line never merges into a
 * "one-time" line of the same product variation (and vice versa).
 */
class SubscribeOrderItemMatcher implements OrderItemMatcherInterface {

  /**
   * The decorated matcher.
   *
   * @var \Drupal\commerce_order\OrderItemMatcherInterface
   */
  protected $inner;

  public function __construct(OrderItemMatcherInterface $inner) {
    $this->inner = $inner;
  }

  /**
   * {@inheritdoc}
   */
  public function match(OrderItemInterface $order_item, array $order_items) {
    $matches = $this->matchAll($order_item, $order_items);
    return count($matches) ? reset($matches) : NULL;
  }

  /**
   * {@inheritdoc}
   */
  public function matchAll(OrderItemInterface $order_item, array $order_items) {
    $matches = $this->inner->matchAll($order_item, $order_items);
    $flag = (bool) $order_item->getData('hs_subscribe');
    return array_values(array_filter($matches, function (OrderItemInterface $candidate) use ($flag) {
      return (bool) $candidate->getData('hs_subscribe') === $flag;
    }));
  }

}
