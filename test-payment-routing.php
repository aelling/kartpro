<?php
/**
 * test-payment-routing.php
 *
 * Simulates what CheckoutController does when a user visits
 * /checkout/{id}/payment, without actually doing a web request.
 * Shows exactly where Commerce thinks the user should be redirected.
 *
 * Run:
 *   cp test-payment-routing.php ~/projects/kartpro/
 *   ddev drush php-script test-payment-routing.php
 */

$order_storage = \Drupal::entityTypeManager()->getStorage('commerce_order');

// Load most recent draft orders
$ids = $order_storage->getQuery()
  ->accessCheck(FALSE)
  ->condition('state', 'draft')
  ->sort('order_id', 'DESC')
  ->range(0, 3)
  ->execute();

foreach ($ids as $oid) {
  $order = $order_storage->load($oid);
  echo "=== ORDER #$oid (checkout_step=" . ($order->get('checkout_step')->value ?? 'null') . ") ===\n";

  // Get the checkout flow entity
  $checkout_flow_entity = $order->get('checkout_flow')->entity;
  if (!$checkout_flow_entity) {
    echo "  ERROR: No checkout_flow on order\n\n";
    continue;
  }
  echo "  Flow: " . $checkout_flow_entity->id() . "\n";

  // Get the checkout order manager service
  $checkout_order_manager = \Drupal::service('commerce_checkout.checkout_order_manager');

  // This is exactly what CheckoutController::checkoutForm() calls
  // to decide where to redirect
  try {
    $step_id = $checkout_order_manager->getCheckoutStepId($order);
    echo "  Commerce says order should be at step: '$step_id'\n";
    echo "  Order's stored step:                   '" . ($order->get('checkout_step')->value ?? 'null') . "'\n";

    if ($step_id !== $order->get('checkout_step')->value) {
      echo "  !! MISMATCH — Commerce will redirect from stored step to '$step_id'\n";
    } else {
      echo "  ✓ Step matches — routing should NOT redirect\n";
    }
  }
  catch (\Exception $e) {
    echo "  EXCEPTION in getCheckoutStepId(): " . $e->getMessage() . "\n";
    echo "  " . $e->getFile() . ":" . $e->getLine() . "\n";
  }

  echo "\n";
}

// -------------------------------------------------------
// Also check: what does the payment step look like now?
// -------------------------------------------------------
echo "=== CURRENT PAYMENT STEP PANES ===\n";
$flows = \Drupal::entityTypeManager()
  ->getStorage('commerce_checkout_flow')
  ->loadMultiple();
$flow = $flows['default'] ?? reset($flows);
$panes = $flow->get('configuration')['panes'] ?? [];
$payment_panes = array_filter($panes, fn($p) => ($p['step'] ?? '') === 'payment');
if (empty($payment_panes)) {
  echo "  !! NO panes on payment step — this causes an immediate redirect !!\n";
} else {
  foreach ($payment_panes as $pid => $pc) {
    printf("  %-35s weight=%d\n", $pid, $pc['weight'] ?? 0);
  }
}
echo "\n";

// -------------------------------------------------------
// Also check: enabled payment gateways
// -------------------------------------------------------
echo "=== ENABLED PAYMENT GATEWAYS ===\n";
$gateways = \Drupal::entityTypeManager()
  ->getStorage('commerce_payment_gateway')
  ->loadByProperties(['status' => TRUE]);
if (empty($gateways)) {
  echo "  !! NO enabled gateways — payment_information has nothing to show,\n";
  echo "     which causes Commerce to skip the payment step entirely\n";
  echo "     and redirect to 'complete' → but order isn't paid → redirect back → LOOP\n";
} else {
  foreach ($gateways as $gw) {
    printf("  %-25s plugin=%s\n", $gw->id(), $gw->getPluginId());
  }
}
echo "\n";

// -------------------------------------------------------
// Check: is payment even required for the order?
// -------------------------------------------------------
echo "=== PAYMENT REQUIREMENT ===\n";
$order = $order_storage->load(reset($ids));
if ($order) {
  $total = $order->getTotalPrice();
  echo "  Order total: " . ($total ? $total->getCurrencyCode() . ' ' . $total->getNumber() : '(none)') . "\n";
  // Commerce skips payment if total is zero
  if ($total && $total->getNumber() == '0') {
    echo "  !! Total is zero — Commerce skips payment step → redirects to complete\n";
    echo "     But if complete requires payment → LOOP\n";
  }
}
echo "\n";
