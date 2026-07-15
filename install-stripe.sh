#!/bin/bash
# install-stripe.sh
# ─────────────────
# Installs and enables Drupal Commerce Stripe payment gateway.
#
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash install-stripe.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — install Commerce Stripe"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Require via Composer ───────────────────────────────────────────────────
echo "1. Running composer require drupal/commerce_stripe..."
echo "   (This may take a minute)"
echo ""
ddev composer require drupal/commerce_stripe

if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: Composer require failed. Check the output above."
  exit 1
fi
echo ""
echo "   ✓ Package installed"
echo ""

# ── 2. Enable the module ──────────────────────────────────────────────────────
echo "2. Enabling commerce_stripe module..."
ddev drush en commerce_stripe -y
echo "   ✓ Module enabled"
echo ""

# ── 3. Clear cache ────────────────────────────────────────────────────────────
echo "3. Clearing cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Get your Stripe API keys from https://dashboard.stripe.com/apikeys"
echo "     You need: Publishable key + Secret key"
echo "     Use TEST keys (pk_test_... / sk_test_...) until you go live."
echo ""
echo "  2. Add the gateway in Drupal:"
echo "     Commerce > Configuration > Payment gateways > Add gateway"
echo "     · Plugin: Stripe"
echo "     · Mode: Test (switch to Live when ready)"
echo "     · Publishable key: pk_test_..."
echo "     · Secret key: sk_test_..."
echo ""
echo "  3. Disable the Manual (test) gateway once Stripe is working."
echo ""
echo "  4. For live payments, also add your webhook endpoint in Stripe dashboard:"
echo "     https://kartpro.ddev.site/payment/notify/stripe"
echo "     (Replace with your live domain before going live)"
echo ""
