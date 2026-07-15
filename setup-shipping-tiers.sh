#!/bin/bash
# setup-shipping-tiers.sh — configures tiered shipping:
#   • Free Shipping     when order total >= $25
#   • Standard Shipping ($5.99) when order total < $25
# Updates the existing "Free Shipping" method and adds "Standard Shipping".
#   cd ~/projects/kartpro && bash setup-shipping-tiers.sh

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

cat > "$DRUPAL_ROOT/hs_shipping_tiers.php" <<'PHP'
<?php

$sm = \Drupal::entityTypeManager()->getStorage('commerce_shipping_method');
$stores = \Drupal::entityTypeManager()->getStorage('commerce_store')->loadMultiple();
$store_ids = array_map(fn($s) => ['target_id' => $s->id()], array_values($stores));

function hs_flat_rate($label, $amount) {
  return [
    'target_plugin_id' => 'flat_rate',
    'target_plugin_configuration' => [
      'rate_label' => $label,
      'rate_amount' => ['number' => $amount, 'currency_code' => 'USD'],
      'services' => ['default'],
    ],
  ];
}
function hs_total_condition($operator) {
  return [[
    'target_plugin_id' => 'order_total_price',
    'target_plugin_configuration' => [
      'operator' => $operator,
      'amount' => ['number' => '25.00', 'currency_code' => 'USD'],
    ],
  ]];
}

// 1. Free Shipping — only for orders >= $25.
$existing = $sm->loadByProperties(['name' => 'Free Shipping']);
$free = $existing ? reset($existing) : $sm->create(['name' => 'Free Shipping', 'status' => TRUE]);
$free->set('stores', $store_ids);
$free->set('plugin', hs_flat_rate('Free shipping', '0.00'));
$free->set('conditions', hs_total_condition('>='));
$free->set('condition_operator', 'AND');
$free->set('weight', 0);
$free->save();
print 'Free Shipping (order total >= $25): id=' . $free->id() . PHP_EOL;

// 2. Standard Shipping — $5.99 flat for orders < $25.
$existing = $sm->loadByProperties(['name' => 'Standard Shipping']);
$std = $existing ? reset($existing) : $sm->create(['name' => 'Standard Shipping', 'status' => TRUE]);
$std->set('stores', $store_ids);
$std->set('plugin', hs_flat_rate('Standard shipping', '5.99'));
$std->set('conditions', hs_total_condition('<'));
$std->set('condition_operator', 'AND');
$std->set('weight', 1);
$std->save();
print 'Standard Shipping ($5.99, order total < $25): id=' . $std->id() . PHP_EOL;

print 'Done.' . PHP_EOL;
PHP

echo "Running shipping config..."
ddev drush php:script hs_shipping_tiers.php
rm -f "$DRUPAL_ROOT/hs_shipping_tiers.php"
echo "Clearing cache..."
ddev drush cr
echo ""
echo "Done. Test at /checkout with a cart under \$25 (should show \$5.99) and over \$25 (free)."
