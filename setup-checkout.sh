#!/bin/bash
# setup-checkout.sh
# ─────────────────
# Configures Drupal Commerce for checkout on HiveSticks:
#   1. Enables required Commerce modules
#   2. Creates a store if one doesn't exist
#   3. Verifies the default checkout flow
#   4. Adds a Manual payment gateway (for testing — replace with Stripe etc.)
#   5. Configures the add-to-cart button to go straight to checkout
#
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash setup-checkout.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — checkout setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Enable required modules ────────────────────────────────────────────────
echo "1. Enabling Commerce modules..."
ddev drush en -y \
  commerce_checkout \
  commerce_payment \
  commerce_payment_example \
  commerce_order \
  commerce_cart \
  2>/dev/null || true
echo "   ✓ Modules enabled (or already were)"
echo ""

# ── 2. PHP setup script ───────────────────────────────────────────────────────
PHP_SCRIPT="$(pwd)/_setup-checkout-tmp.php"

cat > "$PHP_SCRIPT" << 'PHPEOF'
<?php

use Drupal\commerce_store\Entity\Store;
use Drupal\commerce_payment\Entity\PaymentGateway;
use Drupal\commerce_price\Price;
use Drupal\address\LabelHelper;

$em = \Drupal::entityTypeManager();

// ═══════════════════════════════════════════════════════════════════
// 2. Store — create one if none exists
// ═══════════════════════════════════════════════════════════════════
echo "\n2. Checking store...\n";
$stores = $em->getStorage('commerce_store')->loadMultiple();
if (empty($stores)) {
  $store = Store::create([
    'type'             => 'online',
    'uid'              => 1,
    'name'             => 'HiveSticks',
    'mail'             => 'hello@hivesticks.com',
    'default_currency' => 'USD',
    'timezone'         => 'America/Chicago',
    'address'          => [
      'country_code'       => 'US',
      'administrative_area' => 'IA',
      'locality'           => 'Des Moines',
      'postal_code'        => '50309',
      'address_line1'      => '123 Farm Road',
    ],
    'billing_countries' => ['US'],
    'is_default'       => TRUE,
  ]);
  $store->save();
  echo "   ✓ Store created: HiveSticks (ID " . $store->id() . ")\n";
} else {
  $store = reset($stores);
  echo "   · Store already exists: " . $store->label() . " (ID " . $store->id() . ")\n";
}

// ═══════════════════════════════════════════════════════════════════
// 3. Checkout flow — verify default exists
// ═══════════════════════════════════════════════════════════════════
echo "\n3. Checking checkout flow...\n";
$checkout_flows = $em->getStorage('commerce_checkout_flow')->loadMultiple();
if (empty($checkout_flows)) {
  echo "   ⚠ No checkout flow found.\n";
  echo "     Go to: Commerce > Configuration > Checkout flows > Add checkout flow\n";
  echo "     Use the 'Multistep — default' plugin.\n";
} else {
  foreach ($checkout_flows as $flow) {
    echo "   · Flow: " . $flow->label() . " (" . $flow->id() . ")\n";
  }
}

// ═══════════════════════════════════════════════════════════════════
// 4. Payment gateway — add Manual if none exist
// ═══════════════════════════════════════════════════════════════════
echo "\n4. Checking payment gateways...\n";
$gateways = $em->getStorage('commerce_payment_gateway')->loadMultiple();
if (empty($gateways)) {
  if (\Drupal::moduleHandler()->moduleExists('commerce_payment_example')) {
    $gateway = PaymentGateway::create([
      'id'         => 'manual',
      'label'      => 'Manual (test)',
      'plugin'     => 'manual',
      'status'     => TRUE,
      'configuration' => [
        'display_label' => 'Pay by check / invoice',
        'instructions'  => [
          'value'  => 'Mail a check to HiveSticks, 123 Farm Road, Des Moines IA 50309. Orders ship once payment clears.',
          'format' => 'plain_text',
        ],
      ],
    ]);
    $gateway->save();
    echo "   ✓ Manual payment gateway added (for testing)\n";
    echo "     Replace with Stripe/PayPal before going live.\n";
  } else {
    echo "   ⚠ No payment gateways found and commerce_payment_example not available.\n";
    echo "     Add a payment gateway at: Commerce > Configuration > Payment gateways\n";
  }
} else {
  foreach ($gateways as $gw) {
    $status = $gw->status() ? 'enabled' : 'disabled';
    echo "   · Gateway: " . $gw->label() . " ($status)\n";
  }
}

// ═══════════════════════════════════════════════════════════════════
// 5. Order type — set checkout flow + cart behavior
// ═══════════════════════════════════════════════════════════════════
echo "\n5. Checking order type...\n";
$order_types = $em->getStorage('commerce_order_type')->loadMultiple();
if (empty($order_types)) {
  echo "   ⚠ No order types found — Commerce may not be fully installed.\n";
} else {
  foreach ($order_types as $ot) {
    echo "   · Order type: " . $ot->label() . " (" . $ot->id() . ")\n";

    // Set checkout flow to 'default' if a flow exists and none is set
    $checkout_flows = $em->getStorage('commerce_checkout_flow')->loadMultiple();
    $flow_id = $ot->get('checkoutFlowId') ?? $ot->getThirdPartySetting('commerce_checkout', 'checkout_flow');

    // Use the config directly for reliability
    $config = \Drupal::configFactory()->getEditable('commerce_order.commerce_order_type.' . $ot->id());
    $current_flow = $config->get('checkout_flow');
    if (empty($current_flow) && !empty($checkout_flows)) {
      $first_flow = reset($checkout_flows);
      $config->set('checkout_flow', $first_flow->id())->save();
      echo "     ✓ Checkout flow set to: " . $first_flow->label() . "\n";
    } else {
      echo "     · Checkout flow: " . ($current_flow ?: 'not set') . "\n";
    }

    // Ensure cart is enabled
    $cart = $config->get('cart');
    if (empty($cart)) {
      $config->set('cart', 'default')->save();
      echo "     ✓ Cart set to: default\n";
    } else {
      echo "     · Cart: $cart\n";
    }
  }
}

echo "\n";
PHPEOF

echo "Running setup script..."
ddev drush php:script _setup-checkout-tmp.php
rm -f "$PHP_SCRIPT"

echo ""
echo "Clearing cache..."
ddev drush cr

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to check:"
echo ""
echo "  1. Visit the product page and click 'Add to cart'."
echo "     You should be redirected to the cart or see a success message."
echo ""
echo "  2. Visit /cart to see the cart page."
echo ""
echo "  3. Click 'Checkout' — you should see the checkout flow."
echo ""
echo "  4. Before going live, replace the Manual payment gateway:"
echo "     Commerce > Configuration > Payment gateways"
echo "     Add Stripe (commerce_stripe) or PayPal (commerce_paypal)."
echo ""
echo "  5. Update store address/email:"
echo "     Commerce > Configuration > Stores > Edit"
echo ""
