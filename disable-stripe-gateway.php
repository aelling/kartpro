<?php
/**
 * disable-stripe-gateway.php
 * Disables the Stripe payment gateway entity so only Manual remains.
 * This isolates whether Stripe's form building is causing the redirect loop.
 *
 * Run:
 *   cp disable-stripe-gateway.php ~/projects/kartpro/
 *   ddev drush php-script disable-stripe-gateway.php
 */

$gw_storage = \Drupal::entityTypeManager()->getStorage('commerce_payment_gateway');

$stripe = $gw_storage->load('stripe');
if ($stripe) {
  $stripe->setStatus(FALSE);
  $stripe->save();
  echo "✓ Stripe gateway DISABLED.\n";
} else {
  echo "  Stripe gateway not found.\n";
}

$manual = $gw_storage->load('manual');
if ($manual) {
  $manual->setStatus(TRUE);
  $manual->save();
  echo "✓ Manual gateway ENABLED.\n";
} else {
  echo "  Manual gateway not found.\n";
}

echo "\nActive gateways:\n";
foreach ($gw_storage->loadByProperties(['status' => TRUE]) as $gw) {
  printf("  %-20s plugin=%s\n", $gw->id(), $gw->getPluginId());
}

\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "\n✓ Done. Run 'ddev drush cr' then test checkout.\n";
