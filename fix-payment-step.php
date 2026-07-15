<?php
/**
 * fix-payment-step.php
 *
 * Fixes the ERR_TOO_MANY_REDIRECTS on /checkout/{id}/payment.
 *
 * Root cause: stripe_review pane is on the payment step alongside
 * payment_information. stripe_review was designed for a separate "review"
 * step — having both on payment causes Commerce to loop.
 *
 * Fix: move stripe_review to _disabled.
 * The payment step will be: payment_information → payment_process
 * That is the correct flow for Commerce Stripe with Payment Element.
 *
 * Run:
 *   cp fix-payment-step.php ~/projects/kartpro/
 *   ddev drush php-script fix-payment-step.php
 */

$flows = \Drupal::entityTypeManager()
  ->getStorage('commerce_checkout_flow')
  ->loadMultiple();

$flow = $flows['default'] ?? reset($flows);
if (!$flow) {
  echo "ERROR: No checkout flow found.\n";
  return;
}

$config = $flow->get('configuration') ?? [];
$panes  = $config['panes'] ?? [];

echo "Flow: " . $flow->id() . "\n\n";

$changes = [
  // stripe_review conflicts with payment_information on the same step
  'stripe_review' => '_disabled',
];

foreach ($changes as $pane_id => $new_step) {
  if (!isset($panes[$pane_id])) {
    echo "  SKIP  $pane_id — not in this flow\n";
    continue;
  }
  $old = $panes[$pane_id]['step'] ?? '(none)';
  $panes[$pane_id]['step'] = $new_step;
  printf("  MOVE  %-30s %s → %s\n", $pane_id, $old, $new_step);
}

$config['panes'] = $panes;
$flow->set('configuration', $config);
$flow->save();

echo "\n=== Payment step after fix ===\n";
foreach ($flow->get('configuration')['panes'] as $pid => $pc) {
  if (($pc['step'] ?? '') === 'payment') {
    printf("  %-35s weight=%d\n", $pid, $pc['weight'] ?? 0);
  }
}

\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "\n✓ Saved. Run 'ddev drush cr' then test /checkout again.\n";
