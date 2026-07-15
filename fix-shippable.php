<?php
/**
 * fix-shippable.php
 *
 * Makes all product variation types "shippable" so Commerce's
 * shipping_information pane renders on the order_information checkout step.
 *
 * Background:
 *   commerce_shipping's ShippingInformation::isVisible() checks whether the
 *   order contains any "shippable" items.  An item is shippable only if its
 *   product variation type has commerce_shipping.shipment_type set.  Without
 *   this, the pane silently hides itself even when it's in the checkout flow.
 *
 * Run:
 *   cp fix-shippable.php ~/projects/kartpro/
 *   ddev drush php-script fix-shippable.php
 */

if (!\Drupal::moduleHandler()->moduleExists('commerce_shipping')) {
  echo "ERROR: commerce_shipping is not installed.\n";
  echo "Run: ddev drush en commerce_shipping -y\n";
  return;
}

// ── 1. Mark all variation types as shippable ─────────────────────────────────
echo "=== Product variation types ===\n\n";

$variation_type_storage = \Drupal::entityTypeManager()
  ->getStorage('commerce_product_variation_type');
$all_types = $variation_type_storage->loadMultiple();

if (empty($all_types)) {
  echo "WARNING: No product variation types found.\n";
}

foreach ($all_types as $type_id => $type) {
  $current = $type->getThirdPartySetting('commerce_shipping', 'shipment_type');
  printf("  %-30s shipment_type = %s\n", $type_id, $current ?: '(not set)');

  if (!$current) {
    $type->setThirdPartySetting('commerce_shipping', 'shipment_type', 'default');
    $type->save();
    echo "  ✓ Marked '$type_id' as shippable\n\n";
  } else {
    echo "  ✓ Already shippable — no change\n\n";
  }
}

// ── 2. Check the order type has the shipments field ──────────────────────────
echo "=== Order types ===\n\n";

$order_type_storage = \Drupal::entityTypeManager()
  ->getStorage('commerce_order_type');
$order_types = $order_type_storage->loadMultiple();

foreach ($order_types as $order_type_id => $order_type) {
  $has_shipments_field = \Drupal::service('entity_field.manager')
    ->getFieldDefinitions('commerce_order', $order_type_id);
  $has_shipments = isset($has_shipments_field['shipments']);
  printf("  %-30s shipments field = %s\n",
    $order_type_id,
    $has_shipments ? '✓ present' : '✗ MISSING'
  );
  if (!$has_shipments) {
    echo "  → Run: ddev drush cr && ddev drush updb -y to add the shipments field.\n";
  }
}

// ── 3. Check current cart for shippable items ────────────────────────────────
echo "\n=== Cart shippability check ===\n\n";

$carts = \Drupal::entityTypeManager()
  ->getStorage('commerce_order')
  ->loadByProperties(['state' => 'draft', 'cart' => TRUE]);

if (empty($carts)) {
  echo "  (no draft carts found — add something to cart and re-test)\n";
} else {
  foreach ($carts as $cart) {
    echo "  Cart #" . $cart->id() . ":\n";
    foreach ($cart->getItems() as $item) {
      $purchased = $item->getPurchasedEntity();
      if (!$purchased) {
        echo "    - [no purchased entity]\n";
        continue;
      }
      $bundle   = $purchased->bundle();
      $type     = $variation_type_storage->load($bundle);
      $shippable = $type
        ? (bool) $type->getThirdPartySetting('commerce_shipping', 'shipment_type')
        : false;
      printf("    - %-30s (variation type: %s, shippable: %s)\n",
        $item->getTitle(),
        $bundle,
        $shippable ? 'YES ✓' : 'NO ✗'
      );
    }
  }
}

// ── 4. Clear caches ──────────────────────────────────────────────────────────
\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "\n✓ Caches cleared.\n";
echo "Run 'ddev drush cr' then go to checkout — Shipping address form should appear.\n";
