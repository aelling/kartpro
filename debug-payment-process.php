<?php
/**
 * debug-payment-process.php
 *
 * Traces the exact logic PaymentProcess::buildPaneForm() will execute,
 * including what getErrorStepId() and getNextStepId() return,
 * and whether the order has a payment_gateway set.
 *
 * Run:
 *   cp debug-payment-process.php ~/projects/kartpro/
 *   ddev drush php-script debug-payment-process.php
 */

// -------------------------------------------------------
// 1. Load the most recent draft order
// -------------------------------------------------------
$order_storage = \Drupal::entityTypeManager()->getStorage('commerce_order');
$ids = $order_storage->getQuery()
  ->accessCheck(FALSE)
  ->condition('state', 'draft')
  ->sort('order_id', 'DESC')
  ->range(0, 1)
  ->execute();

if (empty($ids)) {
  echo "No draft orders found. Place a new order first.\n";
  return;
}
$order = $order_storage->load(reset($ids));
echo "=== ORDER #" . $order->id() . " ===\n";
echo "  checkout_step:   " . ($order->get('checkout_step')->value ?? '(null)') . "\n";
echo "  payment_gateway: " . ($order->get('payment_gateway')->isEmpty() ? '!! EMPTY !!' : $order->get('payment_gateway')->target_id) . "\n";
echo "  payment_method:  " . ($order->get('payment_method')->isEmpty() ? '(empty)' : $order->get('payment_method')->target_id) . "\n\n";

// -------------------------------------------------------
// 2. Load the checkout flow and inspect steps
// -------------------------------------------------------
$flow_entity = $order->get('checkout_flow')->entity;
echo "=== CHECKOUT FLOW: " . $flow_entity->id() . " ===\n";

// Get the flow plugin
$flow_plugin = $flow_entity->getPlugin();
$steps = $flow_plugin->getSteps();

echo "Steps in order:\n";
$step_ids = array_keys($steps);
foreach ($step_ids as $i => $sid) {
  $step = $steps[$sid];
  $label = $step['label'] ?? $sid;
  echo "  [$i] $sid → $label\n";
}
echo "\n";

// -------------------------------------------------------
// 3. What step comes after 'payment'?
// -------------------------------------------------------
echo "=== STEP NAVIGATION ===\n";
if (method_exists($flow_plugin, 'getNextStepId')) {
  $next = $flow_plugin->getNextStepId('payment');
  echo "  getNextStepId('payment')    = " . ($next ?? '(null/false)') . "\n";
}
if (method_exists($flow_plugin, 'getPreviousStepId')) {
  $prev = $flow_plugin->getPreviousStepId('payment');
  echo "  getPreviousStepId('payment') = " . ($prev ?? '(null/false)') . "\n";
}
echo "\n";

// -------------------------------------------------------
// 4. Check what getErrorStepId() returns for PaymentProcess
//    (replicate it manually: it looks at payment_information step)
// -------------------------------------------------------
echo "=== PAYMENTPROCESS getErrorStepId() SIMULATION ===\n";
$panes_config = $flow_entity->get('configuration')['panes'] ?? [];

$pi_step = $panes_config['payment_information']['step'] ?? '(not found)';
$pp_step = $panes_config['payment_process']['step'] ?? '(not found)';

echo "  payment_information step: $pi_step\n";
echo "  payment_process     step: $pp_step\n";
echo "\n";
echo "  PaymentProcess::getErrorStepId() returns the step of 'payment_information' pane.\n";
echo "  => error_step_id = '$pi_step'\n";

if ($pi_step === $pp_step) {
  echo "\n  !! CONFIRMED BUG: payment_information and payment_process are on the SAME step ('$pi_step')\n";
  echo "     When payment_gateway is empty, PaymentProcess redirects to '$pi_step'\n";
  echo "     which IS the current step → SELF-REDIRECT LOOP.\n";
} else {
  echo "\n  Steps differ — getErrorStepId() would NOT cause a self-redirect.\n";
  echo "  Look for another cause.\n";
}
echo "\n";

// -------------------------------------------------------
// 5. Inspect PaymentProcess source for getErrorStepId
// -------------------------------------------------------
echo "=== PAYMENTPROCESS SOURCE: getErrorStepId ===\n";
$pp_file = '/var/www/html/modules/contrib/commerce/modules/payment/src/Plugin/Commerce/CheckoutPane/PaymentProcess.php';
$source = file_get_contents($pp_file);
if (preg_match('/function getErrorStepId\(\)[^{]*\{([^}]+)\}/s', $source, $m)) {
  echo "  getErrorStepId() body:\n";
  echo "  " . trim($m[1]) . "\n";
} else {
  // Try multiline
  $pos = strpos($source, 'getErrorStepId');
  if ($pos !== false) {
    echo "  Found getErrorStepId at char $pos:\n";
    echo "  " . substr($source, $pos, 300) . "\n";
  } else {
    echo "  getErrorStepId() NOT defined in PaymentProcess → uses base class\n";
  }
}
echo "\n";

// -------------------------------------------------------
// 6. Check the base class getErrorStepId
// -------------------------------------------------------
echo "=== CHECKOUTPANEBASE SOURCE: getErrorStepId ===\n";
$base_file = '/var/www/html/modules/contrib/commerce/modules/checkout/src/Plugin/Commerce/CheckoutPane/CheckoutPaneBase.php';
if (file_exists($base_file)) {
  $base_source = file_get_contents($base_file);
  if (preg_match('/function getErrorStepId\(\)[^{]*\{([^}]+)\}/s', $base_source, $m)) {
    echo "  getErrorStepId() body:\n";
    echo "  " . trim($m[1]) . "\n";
  } else {
    $pos = strpos($base_source, 'getErrorStepId');
    if ($pos !== false) {
      echo "  " . substr($base_source, $pos, 300) . "\n";
    } else {
      echo "  getErrorStepId() NOT in base class either — must be somewhere else\n";
    }
  }
} else {
  echo "  Base class file not found at expected path\n";
}
echo "\n";

// -------------------------------------------------------
// 7. Check PaymentInformation::buildPaneForm for auto-gateway-save
// -------------------------------------------------------
echo "=== PAYMENTINFORMATION SOURCE: auto-gateway save? ===\n";
$pi_file = '/var/www/html/modules/contrib/commerce/modules/payment/src/Plugin/Commerce/CheckoutPane/PaymentInformation.php';
$pi_source = file_get_contents($pi_file);

// Look for 'payment_gateway' set + save inside buildPaneForm
$build_pos = strpos($pi_source, 'function buildPaneForm');
if ($build_pos !== false) {
  // Get the buildPaneForm function body (rough approximation)
  $relevant = substr($pi_source, $build_pos, 2000);
  if (strpos($relevant, "set('payment_gateway'") !== false) {
    echo "  ✓ PaymentInformation::buildPaneForm DOES set payment_gateway on the order\n";
    // Find the snippet
    $set_pos = strpos($relevant, "set('payment_gateway'");
    echo "  Snippet: " . substr($relevant, max(0, $set_pos - 100), 300) . "\n";
  } else {
    echo "  ✗ PaymentInformation::buildPaneForm does NOT set payment_gateway on the order\n";
    echo "    => payment_gateway is empty when PaymentProcess::buildPaneForm() runs\n";
    echo "    => CONFIRMED: This causes 'No payment gateway selected' → redirect loop\n";
  }
} else {
  echo "  Could not find buildPaneForm in PaymentInformation\n";
}
echo "\n";

// -------------------------------------------------------
// 8. Active gateways
// -------------------------------------------------------
echo "=== ACTIVE PAYMENT GATEWAYS ===\n";
$gw_storage = \Drupal::entityTypeManager()->getStorage('commerce_payment_gateway');
$active = $gw_storage->loadByProperties(['status' => TRUE]);
if (empty($active)) {
  echo "  !! NO active gateways!\n";
} else {
  foreach ($active as $gw) {
    printf("  %-20s plugin=%s\n", $gw->id(), $gw->getPluginId());
  }
  // Check if gateways apply to this order
  echo "\n  loadMultipleForOrder() result:\n";
  $applicable = $gw_storage->loadMultipleForOrder($order);
  if (empty($applicable)) {
    echo "  !! EMPTY — no gateways apply to this order (currency/country restriction?)\n";
  } else {
    foreach ($applicable as $gw) {
      printf("  ✓ %-20s applies\n", $gw->id());
    }
  }
}
echo "\n";

// -------------------------------------------------------
// 9. Summary and recommended fix
// -------------------------------------------------------
echo "=== SUMMARY ===\n";
$gw_empty = $order->get('payment_gateway')->isEmpty();
echo "  order->payment_gateway empty: " . ($gw_empty ? 'YES (problem)' : 'NO (ok)') . "\n";
echo "  error_step_id resolves to:    $pi_step\n";
echo "  payment_process on step:      $pp_step\n";

if ($gw_empty && $pi_step === $pp_step) {
  echo "\n  ROOT CAUSE CONFIRMED:\n";
  echo "  PaymentProcess sees empty payment_gateway → redirects to '$pi_step'\n";
  echo "  which is the SAME step → infinite redirect loop.\n";
  echo "\n  RECOMMENDED FIX:\n";
  echo "  Move payment_information to 'order_information' step (runs before payment_process).\n";
  echo "  This way:\n";
  echo "    1. User fills payment_information on order_information step → gateway saved\n";
  echo "    2. payment_process on payment step sees gateway already set → processes payment\n";
  echo "\n  Run fix-payment-pane-steps.php to apply this fix.\n";
}

echo "\n=== DONE ===\n";
