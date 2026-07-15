<?php

namespace Drupal\hs_subscribe\OrderProcessor;

use Drupal\commerce_order\Adjustment;
use Drupal\commerce_order\Entity\OrderInterface;
use Drupal\commerce_order\OrderProcessorInterface;

/**
 * Applies a 15% "Subscribe & save" discount to order items flagged as subscribe.
 */
class SubscribeDiscountProcessor implements OrderProcessorInterface {

  /**
   * {@inheritdoc}
   */
  public function process(OrderInterface $order) {
    foreach ($order->getItems() as $order_item) {
      if (!$order_item->getData('hs_subscribe')) {
        continue;
      }
      $total = $order_item->getTotalPrice();
      if (!$total) {
        continue;
      }
      // 15% off the line total.
      $amount = $total->multiply('-0.15');
      $order_item->addAdjustment(new Adjustment([
        'type' => 'custom',
        'label' => (string) t('Subscribe & save 15%'),
        'amount' => $amount,
        'source_id' => 'hs_subscribe',
      ]));
    }
  }

}
