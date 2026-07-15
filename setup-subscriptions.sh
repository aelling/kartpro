#!/bin/bash
# setup-subscriptions.sh — foundation for Commerce Recurring:
#   • creates an "Every 4 weeks" rolling billing schedule
#   • enables subscriptions on the honey_stick_pack product variation type
# Run AFTER commerce_recurring is installed.
#   cd ~/projects/kartpro && bash setup-subscriptions.sh

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

cat > "$DRUPAL_ROOT/hs_subscriptions.php" <<'PHP'
<?php

// 1. Billing schedule "Every 4 weeks" (rolling).
$bs = \Drupal::entityTypeManager()->getStorage('commerce_billing_schedule');
if (!$bs->load('every_4_weeks')) {
  $schedule = $bs->create([
    'id' => 'every_4_weeks',
    'label' => 'Every 4 weeks',
    'displayLabel' => 'Every 4 weeks',
    'billingType' => 'prepaid',
    'plugin' => 'rolling',
    'configuration' => ['interval' => ['number' => 4, 'unit' => 'week']],
    'prorater' => 'proportional',
    'unpaidSubscriptionState' => 'active',
  ]);
  $schedule->save();
  print 'Created billing schedule: every_4_weeks (Every 4 weeks)' . PHP_EOL;
}
else {
  print 'Billing schedule every_4_weeks already exists' . PHP_EOL;
}

// 2. Enable subscriptions on the honey_stick_pack variation type.
$vt = \Drupal::entityTypeManager()->getStorage('commerce_product_variation_type')->load('honey_stick_pack');
if ($vt) {
  $vt->setThirdPartySetting('commerce_recurring', 'subscription_type', 'product_variation');
  $vt->save();
  print 'Enabled subscriptions on honey_stick_pack (subscription_type=product_variation)' . PHP_EOL;
}
else {
  print 'WARNING: honey_stick_pack variation type not found' . PHP_EOL;
}

print 'Done.' . PHP_EOL;
PHP

echo "Configuring subscriptions..."
ddev drush php:script hs_subscriptions.php
rm -f "$DRUPAL_ROOT/hs_subscriptions.php"
echo "Clearing cache..."
ddev drush cr
echo ""
echo "Done. A billing schedule now exists and the honey-stick variation type allows subscriptions."
echo "Next (to make a product actually subscribable): set the billing schedule on its variations"
echo "at Commerce → Products → [product] → Variations, or tell Claude to script it."
