#!/bin/bash
# create-test-subscription.sh — creates ONE active test subscription for uid 1 so
# the Subscriptions account card can be verified. Safe to delete afterward via the
# admin (Commerce → Subscriptions) or by re-running with DELETE=1.
#   cd ~/projects/kartpro && bash create-test-subscription.sh
#   DELETE=1 bash create-test-subscription.sh   # removes test subscriptions

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

cat > "$DRUPAL_ROOT/hs_test_sub.php" <<'PHP'
<?php

$etm = \Drupal::entityTypeManager();
$sub_storage = $etm->getStorage('commerce_subscription');

if (getenv('DELETE') === '1') {
  $ids = \Drupal::entityQuery('commerce_subscription')->accessCheck(FALSE)
    ->condition('title', 'TEST — %', 'LIKE')->execute();
  if ($ids) { $sub_storage->delete($sub_storage->loadMultiple($ids)); print 'Deleted ' . count($ids) . ' test subscription(s).' . PHP_EOL; }
  else { print 'No test subscriptions to delete.' . PHP_EOL; }
  return;
}

// Find a honey_stick_pack variation to subscribe to.
$vids = \Drupal::entityQuery('commerce_product_variation')->accessCheck(FALSE)
  ->condition('type', 'honey_stick_pack')->range(0, 1)->execute();
if (!$vids) { print 'No honey_stick_pack variations found.' . PHP_EOL; return; }
$variation = $etm->getStorage('commerce_product_variation')->load(reset($vids));

$price = $variation->getPrice();
$sub = $sub_storage->create([
  'type' => 'product_variation',
  'store_id' => 1,
  'billing_schedule' => 'every_4_weeks',
  'uid' => 1,
  'purchased_entity' => $variation->id(),
  'title' => 'TEST — ' . $variation->getOrderItemTitle(),
  'quantity' => 1,
  'unit_price' => $price,
  'state' => 'active',
  'starts' => \Drupal::time()->getRequestTime(),
]);
$sub->save();
print 'Created test subscription id=' . $sub->id() . ' (' . $sub->label() . ')' . PHP_EOL;
print 'State: ' . $sub->getState()->getId() . PHP_EOL;
PHP

echo "Creating test subscription..."
DELETE="${DELETE:-}" ddev drush php:script hs_test_sub.php
rm -f "$DRUPAL_ROOT/hs_test_sub.php"
ddev drush cr
echo ""
echo "Done. Visit /user/1/subscriptions to see the card."
