#!/bin/bash
# deploy-subscribe.sh — installs the hs_subscribe module (PDP subscribe toggle →
# discounted Commerce Recurring subscription) and redeploys pdp.js.
#   cd ~/projects/kartpro && bash deploy-subscribe.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

# ── 1. Module ───────────────────────────────────────────────────────────────
MOD_DIR="$DRUPAL_ROOT/modules/custom/hs_subscribe"
echo "1. Installing hs_subscribe module → $MOD_DIR"
mkdir -p "$MOD_DIR/src/OrderProcessor" "$MOD_DIR/src/EventSubscriber"
cp "$WORKSPACE/hs_subscribe/src/SubscribeOrderItemMatcher.php" "$MOD_DIR/src/SubscribeOrderItemMatcher.php"
cp "$WORKSPACE/hs_subscribe/hs_subscribe.info.yml"     "$MOD_DIR/hs_subscribe.info.yml"
cp "$WORKSPACE/hs_subscribe/hs_subscribe.module"       "$MOD_DIR/hs_subscribe.module"
cp "$WORKSPACE/hs_subscribe/hs_subscribe.services.yml" "$MOD_DIR/hs_subscribe.services.yml"
cp "$WORKSPACE/hs_subscribe/src/OrderProcessor/SubscribeDiscountProcessor.php"   "$MOD_DIR/src/OrderProcessor/SubscribeDiscountProcessor.php"
cp "$WORKSPACE/hs_subscribe/src/EventSubscriber/SubscribeOrderSubscriber.php"    "$MOD_DIR/src/EventSubscriber/SubscribeOrderSubscriber.php"
echo "   ✓ module files copied"

# ── 2. pdp.js (toggle → hidden flag) ────────────────────────────────────────
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then THEME_DIR="$DRUPAL_ROOT/$REL";
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"; fi
if [ -n "$THEME_DIR" ]; then
  cp "$WORKSPACE/pdp.js" "$THEME_DIR/js/pdp.js"
  echo "2. Redeployed pdp.js → $THEME_DIR/js/"
fi

# ── 3. Enable + cache ───────────────────────────────────────────────────────
echo "3. Enabling module + clearing cache..."
ddev drush en hs_subscribe -y
ddev drush cr
echo ""
echo "Done. On a product page: pick 'Subscribe', add to cart → the line gets 15% off"
echo "and a subscription is created when the order is placed (visible at /user/<uid>/subscriptions)."
echo "Recurring CHARGING activates once a recurring-capable payment gateway (Stripe) is configured."
