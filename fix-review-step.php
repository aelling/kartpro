<?php
/**
 * fix-review-step.php
 *
 * Disables the "review" step from the Commerce checkout flow so the flow
 * goes: login → order_information → payment → complete
 * (no intermediate review/confirm step).
 *
 * Run:
 *   cp fix-review-step.php ~/projects/kartpro/
 *   ddev drush php-script fix-review-step.php
 */

$flows = \Drupal::entityTypeManager()
  ->getStorage('commerce_checkout_flow')
  ->loadMultiple();

if (empty($flows)) {
  echo "ERROR: No checkout flows found.\n";
  return;
}

$flow   = $flows['default'] ?? reset($flows);
$config = $flow->get('configuration') ?? [];
$panes  = $config['panes'] ?? [];

echo "Flow: " . $flow->id() . " (" . $flow->label() . ")\n\n";

// Panes to disable (move to _disabled step so they never render)
$to_disable = ['review', 'stripe_review'];
$changed = false;

foreach ($to_disable as $pane_id) {
  if (!isset($panes[$pane_id])) {
    echo "  SKIP $pane_id — not in this flow\n";
    continue;
  }
  $current = $panes[$pane_id]['step'] ?? '(none)';
  if ($current === '_disabled') {
    echo "  OK   $pane_id already disabled\n";
    continue;
  }
  $panes[$pane_id]['step'] = '_disabled';
  echo "  MOVE $pane_id  $current → _disabled\n";
  $changed = true;
}

if (!$changed) {
  echo "\nNothing to change.\n";
  return;
}

$config['panes'] = $panes;
$flow->set('configuration', $config);
$flow->save();
echo "\n✓ Saved checkout flow.\n";

\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "✓ Caches cleared.\n";
echo "\nRun 'ddev drush cr' then test — button should now say 'Continue to payment'.\n";

echo "\n=== Final pane layout ===\n\n";
$final = $flow->get('configuration')['panes'] ?? [];
foreach ($final as $pid => $pc) {
  printf("  %-40s step=%s\n", $pid, $pc['step'] ?? '(none)');
}
