#!/bin/bash
# fix-shippable-variations.sh — makes honey_stick_pack variations shippable so the
# shipping pane (and Free/Standard rate selection) appears at checkout.
#   • adds the 'purchasable_entity_shippable' trait to the variation type (adds weight field)
#   • sets a weight on each variation (≈7g per stick, parsed from SKU)
#   cd ~/projects/kartpro && bash fix-shippable-variations.sh

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

cat > "$DRUPAL_ROOT/hs_shippable.php" <<'PHP'
<?php

$etm = \Drupal::entityTypeManager();
$trait_manager = \Drupal::service('plugin.manager.commerce_entity_trait');

// 1. Add the shippable trait to the honey_stick_pack variation type.
$vt = $etm->getStorage('commerce_product_variation_type')->load('honey_stick_pack');
$traits = $vt->getTraits();
if (!in_array('purchasable_entity_shippable', $traits, TRUE)) {
  $trait = $trait_manager->createInstance('purchasable_entity_shippable');
  $trait_manager->installTrait($trait, 'commerce_product_variation', 'honey_stick_pack');
  $traits[] = 'purchasable_entity_shippable';
  $vt->setTraits($traits);
  $vt->save();
  print 'Added shippable trait to honey_stick_pack (weight field installed).' . PHP_EOL;
}
else {
  print 'honey_stick_pack already shippable.' . PHP_EOL;
}

// 2. Give each variation a weight (≈7g per stick from the SKU number).
$ids = \Drupal::entityQuery('commerce_product_variation')->accessCheck(FALSE)
  ->condition('type', 'honey_stick_pack')->execute();
$updated = 0;
foreach ($etm->getStorage('commerce_product_variation')->loadMultiple($ids) as $v) {
  if ($v->hasField('weight') && $v->get('weight')->isEmpty()) {
    $count = preg_match('/(\d+)/', (string) $v->getSku(), $m) ? (int) $m[1] : 30;
    $grams = max(50, $count * 7);
    $v->set('weight', ['number' => $grams, 'unit' => 'g']);
    $v->save();
    $updated++;
  }
}
print "Set weight on {$updated} variation(s)." . PHP_EOL;
print 'Done.' . PHP_EOL;
PHP

echo "Making variations shippable..."
ddev drush php:script hs_shippable.php
rm -f "$DRUPAL_ROOT/hs_shippable.php"
echo "Clearing cache..."
ddev drush cr
echo ""
echo "Now: empty your cart, re-add a product, and go to checkout — the Shipping"
echo "address + Free/Standard method selection should appear. (Existing cart order"
echo "16 predates the change; a fresh cart will pick up shippability.)"
