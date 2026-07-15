<?php
/**
 * diagnose-checkout.php
 *
 * Diagnoses why /checkout/{id}/payment is redirect-looping.
 * Checks: order state, checkout_step, pane config, gateways, shipments field.
 *
 * Run:
 *   cp diagnose-checkout.php ~/projects/kartpro/
 *   ddev drush php-script diagnose-checkout.php
 */

$order_storage = \Drupal::entityTypeManager()->getStorage('commerce_order');

// Try to find the most recent order
$all_orders = $order_storage->getQuery()
  ->accessCheck(FALSE)
  ->sort('order_id', 'DESC')
  ->range(0, 5)
  ->execute();

echo "=== RECENT ORDERS ===\n";
foreach ($all_orders as $oid) {
  $o = $order_storage->load($oid);
  printf("  #%d  state=%-12s  checkout_step=%-20s  email=%s\n",
    $oid,
    $o->getState()->getId(),
    $o->get('checkout_step')->value ?? '(none)',
    $o->getEmail() ?? '(guest)'
  );
}
echo "\n";

// Load the order we're debugging (most recent draft)
$order = null;
foreach ($all_orders as $oid) {
  $o = $order_storage->load($oid);
  if (in_array($o->getState()->getId(), ['draft', 'pending'])) {
    $order = $o;
    break;
  }
}
if (!$order) {
  $order = $order_storage->load(reset($all_orders));
}

echo "=== DEBUGGING ORDER #" . $order->id() . " ===\n";
echo "  State:         " . $order->getState()->getId() . "\n";
echo "  Checkout step: " . ($order->get('checkout_step')->value ?? '(none)') . "\n";
echo "  Order type:    " . $order->bundle() . "\n";
echo "  Email:         " . ($order->getEmail() ?? '(none)') . "\n\n";

// -------------------------------------------------------
// 1. Checkout flow pane layout
// -------------------------------------------------------
echo "=== CHECKOUT FLOW PANES ===\n";
$flows = \Drupal::entityTypeManager()
  ->getStorage('commerce_checkout_flow')
  ->loadMultiple();
$flow = $flows['default'] ?? reset($flows);
if ($flow) {
  $panes = $flow->get('configuration')['panes'] ?? [];
  // Group by step
  $by_step = [];
  foreach ($panes as $pid => $pc) {
    $by_step[$pc['step'] ?? 'unknown'][] = [$pid, $pc['weight'] ?? 0];
  }
  ksort($by_step);
  foreach ($by_step as $step => $plist) {
    echo "  Step: $step\n";
    usort($plist, fn($a, $b) => $a[1] <=> $b[1]);
    foreach ($plist as [$pid, $w]) {
      printf("    %-35s weight=%d\n", $pid, $w);
    }
  }
} else {
  echo "  !! No checkout flow found !!\n";
}
echo "\n";

// -------------------------------------------------------
// 2. Payment gateways
// -------------------------------------------------------
echo "=== PAYMENT GATEWAYS ===\n";
$gw_storage = \Drupal::entityTypeManager()->getStorage('commerce_payment_gateway');
$gateways = $gw_storage->loadMultiple();
if (empty($gateways)) {
  echo "  !! NO PAYMENT GATEWAYS CONFIGURED — this causes an immediate redirect !!\n";
} else {
  foreach ($gateways as $gw) {
    printf("  %-25s plugin=%-25s status=%s\n",
      $gw->id(),
      $gw->getPluginId(),
      $gw->status() ? 'ENABLED' : 'disabled'
    );
    // Show gateway configuration (sanitized)
    $cfg = $gw->getPluginConfiguration();
    if (isset($cfg['mode'])) {
      echo "    mode=" . $cfg['mode'] . "\n";
    }
    if (isset($cfg['publishable_key'])) {
      $pk = $cfg['publishable_key'];
      echo "    publishable_key=" . substr($pk, 0, 12) . "...\n";
    }
    if (isset($cfg['secret_key'])) {
      $sk = $cfg['secret_key'];
      echo "    secret_key=" . substr($sk, 0, 12) . "...\n";
    }
  }
}
echo "\n";

// -------------------------------------------------------
// 3. Shipments field on order type
// -------------------------------------------------------
echo "=== SHIPMENTS FIELD ===\n";
$field_manager = \Drupal::service('entity_field.manager');
$field_manager->clearCachedFieldDefinitions();
$order_type = $order->bundle();
$defs = $field_manager->getFieldDefinitions('commerce_order', $order_type);
echo "  shipments field on '$order_type': " . (isset($defs['shipments']) ? '✓ present' : '✗ MISSING') . "\n";

// Check all order types
$order_types = \Drupal::entityTypeManager()->getStorage('commerce_order_type')->loadMultiple();
foreach ($order_types as $tid => $t) {
  $d = $field_manager->getFieldDefinitions('commerce_order', $tid);
  printf("  %-20s shipments=%s\n", $tid, isset($d['shipments']) ? '✓' : '✗ MISSING');
}
echo "\n";

// -------------------------------------------------------
// 4. Product variation shippable flag
// -------------------------------------------------------
echo "=== PRODUCT VARIATION TYPES (shippable) ===\n";
$vt_storage = \Drupal::entityTypeManager()->getStorage('commerce_product_variation_type');
foreach ($vt_storage->loadMultiple() as $vt_id => $vt) {
  $tp = $vt->getThirdPartySetting('commerce_shipping', 'shipment_type');
  printf("  %-30s shipment_type=%s\n", $vt_id, $tp ?? '(not set — NOT shippable)');
}
echo "\n";

// -------------------------------------------------------
// 5. Order's existing shipments
// -------------------------------------------------------
echo "=== ORDER SHIPMENTS ===\n";
if ($order->hasField('shipments')) {
  $shipments = $order->get('shipments')->referencedEntities();
  if (empty($shipments)) {
    echo "  No shipments yet on this order\n";
  } else {
    foreach ($shipments as $sh) {
      echo "  Shipment #" . $sh->id() . " state=" . $sh->getState()->getId() . "\n";
      $addr = $sh->getShippingAddress();
      echo "  Address: " . ($addr ? ($addr->getAddressLine1() . ', ' . $addr->getLocality()) : '(none)') . "\n";
    }
  }
} else {
  echo "  Order has no shipments field at all\n";
}
echo "\n";

// -------------------------------------------------------
// 6. commerce_shipping module status
// -------------------------------------------------------
echo "=== MODULE STATUS ===\n";
$modules = ['commerce_shipping', 'commerce_stripe', 'commerce_payment'];
foreach ($modules as $m) {
  $installed = \Drupal::moduleHandler()->moduleExists($m);
  echo "  $m: " . ($installed ? '✓ installed' : '✗ NOT installed') . "\n";
}
echo "\n";

echo "=== DONE ===\n";
echo "Look for:\n";
echo "  - No payment gateways / all disabled → payment step has nothing to render → redirects\n";
echo "  - shipments field MISSING → shipping pane can't save → order_information never completes\n";
echo "  - checkout_step stuck on 'order_information' → payment step refuses access\n";
