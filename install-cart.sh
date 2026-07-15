#!/bin/bash
# install-cart.sh
# ───────────────
# Deploys all HiveSticks cart page assets to the custom theme.
# Run from anywhere — the script cd's into kartpro automatically.
#
# Usage:
#   bash install-cart.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

# DDEV requires commands to run from inside the project directory
cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks Cart — theme install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Find theme ──────────────────────────────────────────────────────────────
echo "1. Detecting active theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "   ERROR: Could not detect theme. Is DDEV running? (ddev start)"
  exit 1
fi
THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  echo "   ERROR: Theme directory not found for '$THEME'"
  exit 1
fi
echo "   Theme: $THEME → $THEME_DIR"
echo ""

# ── 2. Twig templates ──────────────────────────────────────────────────────────
echo "2. Installing Twig templates..."
TWIG_DIR="$THEME_DIR/templates/commerce"
mkdir -p "$TWIG_DIR"
cp "$WORKSPACE/views-view--commerce-cart-form.html.twig"        "$TWIG_DIR/"
cp "$WORKSPACE/commerce-order-total-summary.html.twig"          "$TWIG_DIR/"
cp "$WORKSPACE/commerce-product-variation--cart.html.twig"      "$TWIG_DIR/"
echo "   ✓ views-view--commerce-cart-form.html.twig          → $TWIG_DIR/"
echo "   ✓ commerce-order-total-summary.html.twig            → $TWIG_DIR/"
echo "   ✓ commerce-product-variation--cart.html.twig        → $TWIG_DIR/"
echo ""

# ── 3. CSS ─────────────────────────────────────────────────────────────────────
echo "3. Installing CSS..."
CSS_DIR="$THEME_DIR/css"
mkdir -p "$CSS_DIR"
cp "$WORKSPACE/cart.css" "$CSS_DIR/cart.css"
echo "   ✓ cart.css → $CSS_DIR/"
echo ""

# ── 4. JS ──────────────────────────────────────────────────────────────────────
echo "4. Installing JS..."
JS_DIR="$THEME_DIR/js"
mkdir -p "$JS_DIR"
cp "$WORKSPACE/cart.js" "$JS_DIR/cart.js"
echo "   ✓ cart.js → $JS_DIR/"
echo ""

# ── 5. Libraries YAML ──────────────────────────────────────────────────────────
echo "5. Installing hivesticks.libraries.yml..."
cp "$WORKSPACE/hivesticks.libraries.yml" "$THEME_DIR/${THEME}.libraries.yml"
echo "   ✓ ${THEME}.libraries.yml → $THEME_DIR/"
echo ""

# ── 6. Enable title field in cart display mode (idempotent) ───────────────────
echo "6. Enabling title field in Commerce cart display mode..."
PHP_SCRIPT="$WORKSPACE/fix-cart-display.php"
TEMP_SCRIPT="$DRUPAL_ROOT/fix-cart-display.php"
if [ -f "$PHP_SCRIPT" ]; then
  # Copy into the project dir so the DDEV web container can see it
  cp "$PHP_SCRIPT" "$TEMP_SCRIPT"
  ddev drush php:script fix-cart-display.php
  rm -f "$TEMP_SCRIPT"
else
  echo "   WARN: fix-cart-display.php not found at $PHP_SCRIPT — skipping."
fi
echo ""

# ── 7. Clear Drupal cache ──────────────────────────────────────────────────────
echo "7. Clearing Drupal cache..."
ddev drush cr
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Add something to your cart on the PDP, then visit:"
echo "     https://kartpro.ddev.site/cart"
echo ""
echo "  2. If the layout looks wrong, check the browser console for"
echo "     the exact table/row class names Commerce is rendering,"
echo "     then adjust cart.css selectors to match."
echo ""
echo "  3. If 'Proceed to checkout' 404s, make sure Commerce checkout"
echo "     is configured: Commerce > Configuration > Checkout flows"
echo ""
