<?php
/**
 * fix-payment-pane-steps.php
 *
 * FIXES THE ERR_TOO_MANY_REDIRECTS on /checkout/N/payment.
 *
 * ROOT CAUSE:
 *   PaymentProcess::buildPaneForm() calls redirectToStep($error_step_id)
 *   when order->payment_gateway is empty (i.e., on every initial page load).
 *   getErrorStepId() returns payment_information->getStepId() = 'payment'.
 *   Both panes are on 'payment' → self-redirect loop.
 *
 * FIX:
 *   Move payment_information to the order_information step.
 *   Now getErrorStepId() = 'order_information' (not 'payment').
 *   User selects gateway on order_information step → gateway saved to order.
 *   payment_process on payment step sees gateway → processes → redirects to complete.
 *
 * This is the STANDARD Commerce checkout flow:
 *   order_information: contact + shipping + payment_information (gateway + billing)
 *   payment:          payment_process (processes payment silently, redirects to complete)
 *   complete:         order complete page
 *
 * Run:
 *   cp fix-payment-pane-steps.php ~/projects/kartpro/
 *   ddev drush php-script fix-payment-pane-steps.php
 */

$flow_storage = \Drupal::entityTypeManager()->getStorage('commerce_checkout_flow');
$flows = $flow_storage->loadMultiple();
$flow = $flows['default'] ?? reset($flows);

if (!$flow) {
  echo "ERROR: No checkout flow found.\n";
  return;
}

echo "=== Checkout flow: " . $flow->id() . " ===\n\n";

$config = $flow->get('configuration');
$panes = $config['panes'] ?? [];

// Show current config
echo "Current pane configuration:\n";
foreach ($panes as $pid => $pc) {
  printf("  %-28s  step=%-20s  weight=%d\n", $pid, $pc['step'] ?? '?', $pc['weight'] ?? 0);
}
echo "\n";

// --- Determine correct weight for payment_information on order_information ---
// Find the highest weight on order_information so we can put payment_information last.
$max_weight_on_oi = 0;
foreach ($panes as $pid => $pc) {
  if (($pc['step'] ?? '') === 'order_information' && $pid !== 'payment_information') {
    $w = $pc['weight'] ?? 0;
    if ($w > $max_weight_on_oi) {
      $max_weight_on_oi = $w;
    }
  }
}
$pi_weight = $max_weight_on_oi + 5;

// --- Make changes ---
$changes = [];

// 1. Move payment_information to order_information
if (isset($panes['payment_information'])) {
  $old_step = $panes['payment_information']['step'] ?? '?';
  if ($old_step !== 'order_information') {
    $panes['payment_information']['step'] = 'order_information';
    $panes['payment_information']['weight'] = $pi_weight;
    $changes[] = "payment_information: $old_step → order_information (weight=$pi_weight)";
  } else {
    echo "  payment_information already on order_information — no change needed.\n";
  }
}

// 2. Ensure payment_process stays on payment step
if (isset($panes['payment_process'])) {
  $pp_step = $panes['payment_process']['step'] ?? '?';
  if ($pp_step !== 'payment') {
    $panes['payment_process']['step'] = 'payment';
    $panes['payment_process']['weight'] = 10;
    $changes[] = "payment_process: $pp_step → payment (weight=10)";
  } else {
    echo "  payment_process already on payment step — no change.\n";
  }
}

// 3. stripe_review stays _disabled (we already moved it there)
if (isset($panes['stripe_review'])) {
  if (($panes['stripe_review']['step'] ?? '') !== '_disabled') {
    $panes['stripe_review']['step'] = '_disabled';
    $changes[] = "stripe_review: → _disabled";
  }
}

if (empty($changes)) {
  echo "No changes needed — flow already correctly configured.\n\n";
} else {
  echo "Changes to apply:\n";
  foreach ($changes as $c) {
    echo "  → $c\n";
  }
  echo "\n";

  $config['panes'] = $panes;
  $flow->set('configuration', $config);
  $flow->save();
  echo "✓ Checkout flow saved.\n\n";
}

// --- Verify ---
echo "=== New pane configuration ===\n";
$flow = $flow_storage->load($flow->id()); // reload
$panes_new = $flow->get('configuration')['panes'] ?? [];
foreach ($panes_new as $pid => $pc) {
  printf("  %-28s  step=%-20s  weight=%d\n", $pid, $pc['step'] ?? '?', $pc['weight'] ?? 0);
}
echo "\n";

// Confirm the fix
$pi_step_new = $panes_new['payment_information']['step'] ?? '?';
$pp_step_new = $panes_new['payment_process']['step'] ?? '?';
echo "=== Fix verification ===\n";
echo "  payment_information step: $pi_step_new\n";
echo "  payment_process     step: $pp_step_new\n";
if ($pi_step_new !== $pp_step_new) {
  echo "\n  ✓ FIXED: panes are now on DIFFERENT steps.\n";
  echo "    getErrorStepId() = '$pi_step_new' ≠ '$pp_step_new'\n";
  echo "    Self-redirect loop is broken.\n";
} else {
  echo "\n  ✗ Still on same step — something went wrong.\n";
}

// Clear caches
\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "\n✓ Caches cleared.\n";
echo "\nNext steps:\n";
echo "  1. ddev drush cr\n";
echo "  2. Visit the site in a fresh incognito window\n";
echo "  3. Add item to cart, checkout\n";
echo "  4. Order information step should now show:\n";
echo "     - Contact info (email)\n";
echo "     - Shipping address\n";
echo "     - Payment method selection + billing address\n";
echo "  5. After clicking Continue, should go to payment step\n";
echo "     (briefly) then complete → order success page\n";
