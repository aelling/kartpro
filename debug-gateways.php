<?php
/**
 * debug-gateways.php
 *
 * Checks exactly what payment gateways are available for the most recent order,
 * and whether any gateway plugin throws an exception on instantiation.
 * Also checks if the Stripe PHP SDK is installed.
 *
 * Run:
 *   cp debug-gateways.php ~/projects/kartpro/
 *   ddev drush php-script debug-gateways.php
 */

// Get most recent order
$order_storage = \Drupal::entityTypeManager()->getStorage('commerce_order');
$ids = $order_storage->getQuery()
  ->accessCheck(FALSE)
  ->sort('order_id', 'DESC')
  ->range(0, 1)
  ->execute();
$order = $order_storage->load(reset($ids));
echo "=== Order #" . $order->id() . " ===\n\n";

// -------------------------------------------------------
// 1. Load all payment gateways and test each plugin
// -------------------------------------------------------
echo "=== PAYMENT GATEWAYS ===\n";
$gw_storage = \Drupal::entityTypeManager()->getStorage('commerce_payment_gateway');
$all_gateways = $gw_storage->loadMultiple();

foreach ($all_gateways as $gw) {
  $status = $gw->status() ? 'ENABLED' : 'disabled';
  printf("  %-20s  plugin=%-30s  status=%s\n", $gw->id(), $gw->getPluginId(), $status);

  // Try to get the plugin (this is where it can crash)
  try {
    $plugin = $gw->getPlugin();
    echo "    ✓ Plugin loaded: " . get_class($plugin) . "\n";

    // Test applies()
    try {
      $applies = $gw->applies($order);
      echo "    applies(order): " . ($applies ? '✓ YES' : '✗ NO') . "\n";
    } catch (\Exception $e) {
      echo "    ✗ applies() EXCEPTION: " . $e->getMessage() . "\n";
    }
  } catch (\Exception $e) {
    echo "    ✗ getPlugin() EXCEPTION: " . $e->getMessage() . "\n";
    echo "      " . $e->getFile() . ":" . $e->getLine() . "\n";
  }
}

// -------------------------------------------------------
// 2. What loadMultipleForOrder() actually returns
// -------------------------------------------------------
echo "\n=== loadMultipleForOrder() result ===\n";
try {
  $available = $gw_storage->loadMultipleForOrder($order);
  if (empty($available)) {
    echo "  !! EMPTY — no gateways available for this order !!\n";
    echo "  This causes payment_information to call redirectToStep('payment') → self-redirect loop\n";
  } else {
    foreach ($available as $gw) {
      echo "  ✓ " . $gw->id() . " (" . $gw->getPluginId() . ")\n";
    }
  }
} catch (\Exception $e) {
  echo "  ✗ EXCEPTION: " . $e->getMessage() . "\n";
}

// -------------------------------------------------------
// 3. Stripe PHP SDK
// -------------------------------------------------------
echo "\n=== STRIPE PHP SDK ===\n";
if (class_exists('\Stripe\Stripe')) {
  echo "  ✓ Stripe\\Stripe class found — SDK is installed\n";
} else {
  echo "  ✗ Stripe\\Stripe class NOT found — SDK missing!\n";
  echo "  Run: ddev exec composer require stripe/stripe-php\n";
}

// -------------------------------------------------------
// 4. Check for payment_information pane error step
// -------------------------------------------------------
echo "\n=== PAYMENT PANE CONFIG ===\n";
$flows = \Drupal::entityTypeManager()
  ->getStorage('commerce_checkout_flow')
  ->loadMultiple();
$flow = $flows['default'] ?? reset($flows);
$panes = $flow->get('configuration')['panes'] ?? [];
foreach (['payment_information', 'payment_process', 'stripe_review'] as $pid) {
  if (isset($panes[$pid])) {
    printf("  %-25s  step=%-15s  weight=%d\n",
      $pid, $panes[$pid]['step'] ?? '?', $panes[$pid]['weight'] ?? 0);
  }
}

// -------------------------------------------------------
// 5. Shipping information for the order
// -------------------------------------------------------
echo "\n=== SHIPPING STATUS ===\n";
$field_manager = \Drupal::service('entity_field.manager');
$field_manager->clearCachedFieldDefinitions();
$defs = $field_manager->getFieldDefinitions('commerce_order', $order->bundle());
echo "  shipments field: " . (isset($defs['shipments']) ? '✓ present' : '✗ MISSING') . "\n";
if ($order->hasField('shipments')) {
  $shipments = $order->get('shipments')->referencedEntities();
  echo "  shipments on order: " . count($shipments) . "\n";
}
foreach ($order->getItems() as $item) {
  $entity = $item->getPurchasedEntity();
  if ($entity) {
    $type_storage = \Drupal::entityTypeManager()->getStorage($entity->getEntityTypeId() . '_type');
    $vt = $type_storage->load($entity->bundle());
    $shipment_type = $vt ? $vt->getThirdPartySetting('commerce_shipping', 'shipment_type') : null;
    printf("  Item variation type %-20s  shipment_type=%s\n",
      $entity->bundle(), $shipment_type ?? '(not set)');
  }
}

echo "\n=== DONE ===\n";
