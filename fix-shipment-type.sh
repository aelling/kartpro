#!/bin/bash
# fix-shipment-type.sh — the order type has no shipment type assigned, so the
# shipping packer throws "Missing required property type" at checkout. This
# ensures a shipment type exists and points the default order type at it.
#   cd ~/projects/kartpro && bash fix-shipment-type.sh

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

cat > "$DRUPAL_ROOT/hs_shipment_type.php" <<'PHP'
<?php

$etm = \Drupal::entityTypeManager();

// 1. Ensure a shipment type exists (reuse existing, else create 'default').
$st_storage = $etm->getStorage('commerce_shipment_type');
$types = $st_storage->loadMultiple();
if ($types) {
  $type_id = array_key_first($types);
  print 'Using existing shipment type: ' . $type_id . PHP_EOL;
}
else {
  $st_storage->create([
    'id' => 'default',
    'label' => 'Default',
    'profileType' => 'customer',
  ])->save();
  $type_id = 'default';
  print 'Created shipment type: default (profile type: customer)' . PHP_EOL;
}

// 2. Point the default order type at that shipment type.
$ot = $etm->getStorage('commerce_order_type')->load('default');
$was = $ot->getThirdPartySetting('commerce_shipping', 'shipment_type');
$ot->setThirdPartySetting('commerce_shipping', 'shipment_type', $type_id);
$ot->save();
print 'Order type "default" shipment_type: ' . var_export($was, TRUE) . ' -> ' . $type_id . PHP_EOL;
print 'Done.' . PHP_EOL;
PHP

echo "Wiring up shipment type..."
ddev drush php:script hs_shipment_type.php
rm -f "$DRUPAL_ROOT/hs_shipment_type.php"
echo "Clearing cache..."
ddev drush cr
echo ""
echo "Retry checkout — the shipping address + Free/Standard method should now load."
