<?php
/**
 * debug-stripe-api.php
 *
 * Tests whether the Stripe API keys actually work by making a real API call.
 * Also shows what PaymentInformation::buildPaneForm() would encounter.
 *
 * Run:
 *   cp debug-stripe-api.php ~/projects/kartpro/
 *   ddev drush php-script debug-stripe-api.php
 */

// -------------------------------------------------------
// 1. Get Stripe keys from gateway config
// -------------------------------------------------------
$gw_storage = \Drupal::entityTypeManager()->getStorage('commerce_payment_gateway');
$stripe_gw = $gw_storage->load('stripe');
if (!$stripe_gw) {
  echo "ERROR: Stripe gateway entity not found.\n";
  return;
}

$cfg = $stripe_gw->getPluginConfiguration();
$secret_key = $cfg['secret_key'] ?? '(not set)';
$pub_key    = $cfg['publishable_key'] ?? '(not set)';
$mode       = $cfg['mode'] ?? '(not set)';

echo "=== STRIPE GATEWAY CONFIG ===\n";
echo "  Mode:            $mode\n";
echo "  Publishable key: $pub_key\n";
echo "  Secret key:      " . substr($secret_key, 0, 20) . "...\n\n";

// -------------------------------------------------------
// 2. Validate key format
// -------------------------------------------------------
echo "=== KEY VALIDATION ===\n";
$pub_valid = str_starts_with($pub_key, 'pk_test_') || str_starts_with($pub_key, 'pk_live_');
$sec_valid = str_starts_with($secret_key, 'sk_test_') || str_starts_with($secret_key, 'sk_live_');
echo "  Publishable key format: " . ($pub_valid ? '✓ valid' : '✗ INVALID (should start with pk_test_ or pk_live_)') . "\n";
echo "  Secret key format:      " . ($sec_valid ? '✓ valid' : '✗ INVALID (should start with sk_test_ or sk_live_)') . "\n\n";

if (!$sec_valid) {
  echo "STOP: Secret key format is wrong. Fix the Stripe gateway config.\n";
  echo "  Go to: /admin/commerce/config/payment-gateways/manage/stripe\n";
  return;
}

// -------------------------------------------------------
// 3. Test actual Stripe API call
// -------------------------------------------------------
echo "=== STRIPE API TEST ===\n";
try {
  \Stripe\Stripe::setApiKey($secret_key);
  $intent = \Stripe\PaymentIntent::create([
    'amount'   => 1000,  // $10.00
    'currency' => 'usd',
    'automatic_payment_methods' => ['enabled' => true],
  ]);
  echo "  ✓ Payment intent created: " . $intent->id . "\n";
  echo "  ✓ Stripe API keys are valid and working!\n\n";

  // Clean up — cancel the test intent
  $intent->cancel();
  echo "  ✓ Test intent cancelled.\n";
}
catch (\Stripe\Exception\AuthenticationException $e) {
  echo "  ✗ AUTHENTICATION ERROR: " . $e->getMessage() . "\n";
  echo "  → The secret key is wrong or has been revoked.\n";
  echo "  → Go to: https://dashboard.stripe.com/test/apikeys\n";
  echo "  → Then update: /admin/commerce/config/payment-gateways/manage/stripe\n\n";
}
catch (\Stripe\Exception\ApiConnectionException $e) {
  echo "  ✗ CONNECTION ERROR: " . $e->getMessage() . "\n";
  echo "  → DDEV container may not have internet access to Stripe's API.\n";
  echo "  → This would cause PaymentInformation::buildPaneForm() to redirect.\n\n";
}
catch (\Exception $e) {
  echo "  ✗ ERROR (" . get_class($e) . "): " . $e->getMessage() . "\n\n";
}

// -------------------------------------------------------
// 4. Check if DDEV has outbound internet access
// -------------------------------------------------------
echo "=== DDEV INTERNET ACCESS ===\n";
$result = @file_get_contents('https://api.stripe.com/', false,
  stream_context_create(['http' => ['timeout' => 5]])
);
if ($result !== false || (isset($http_response_header) && strpos($http_response_header[0], 'HTTP/') !== false)) {
  echo "  ✓ Can reach api.stripe.com\n";
} else {
  $err = error_get_last();
  echo "  ✗ CANNOT reach api.stripe.com: " . ($err['message'] ?? 'unknown error') . "\n";
  echo "  → This is likely why PaymentInformation fails and redirects.\n";
  echo "  → DDEV containers often block outbound HTTPS. Check ddev config.\n";
}

echo "\n=== DONE ===\n";
