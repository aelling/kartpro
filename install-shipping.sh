#!/bin/bash
# install-shipping.sh
# ───────────────────────────────────────────────────────────────────────────────
# Installs and configures Commerce shipping for HiveSticks.
#
# What it does:
#   1. Requires drupal/commerce_shipping via Composer (if not already installed)
#   2. Enables the commerce_shipping module via Drush
#   3. Runs setup-shipping.php to:
#        - Create a "Free Shipping" flat-rate method
#        - Add shipping_information pane to the order_information checkout step
#   4. Clears caches
#
# Run from WSL:
#   bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/install-shipping.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — shipping install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Require the module via Composer (idempotent) ──────────────────────────
echo "── Step 1: Composer require commerce_shipping ──"
if ddev composer show drupal/commerce_shipping 2>/dev/null | grep -q 'drupal/commerce_shipping'; then
  echo "✓ drupal/commerce_shipping already in composer.json"
else
  ddev composer require drupal/commerce_shipping
  if [ $? -ne 0 ]; then
    echo "ERROR: Composer require failed. Check your composer.json / network."
    exit 1
  fi
  echo "✓ drupal/commerce_shipping added"
fi
echo ""

# ── 2. Enable the module ─────────────────────────────────────────────────────
echo "── Step 2: Enable commerce_shipping ──"
if ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -q "^commerce_shipping$"; then
  echo "✓ commerce_shipping already enabled"
else
  ddev drush en commerce_shipping -y
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable commerce_shipping."
    echo "  Try manually: ddev drush en commerce_shipping -y"
    exit 1
  fi
  echo "✓ commerce_shipping enabled"
fi
echo ""

# ── 3. Run the PHP setup script ──────────────────────────────────────────────
echo "── Step 3: Configure shipping method + checkout pane ──"
cp "$WORKSPACE/setup-shipping.php" "$DRUPAL_ROOT/"
ddev drush php-script setup-shipping.php
rm -f "$DRUPAL_ROOT/setup-shipping.php"
echo ""

# ── 4. Full cache rebuild ────────────────────────────────────────────────────
echo "── Step 4: Cache rebuild ──"
ddev drush cr
echo "✓ Cache rebuilt"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done! Next:"
echo "  1. Add an item to cart"
echo "  2. Go through checkout as guest"
echo "  3. order_information step should now"
echo "     show: Contact info → Shipping address"
echo ""
echo "  If you see 'No shipping rates available':"
echo "  Commerce → Configuration → Shipping methods"
echo "  → Free Shipping → edit → enable + attach store"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
