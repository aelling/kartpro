#!/bin/bash
# install-checkout.sh
# ───────────────────
# Deploys ONLY the checkout CSS + template to the HiveSticks theme.
# Run this from your WSL terminal:
#   bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/install-checkout.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

# ── Find theme ──────────────────────────────────────────────────────────────
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd to $DRUPAL_ROOT — is the path right?"; exit 1; }

THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "ERROR: Could not detect theme. Is DDEV running? Try: ddev start"
  exit 1
fi

THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  echo "ERROR: Theme directory not found for '$THEME'"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — checkout deploy"
echo " Theme: $THEME"
echo " Dir:   $THEME_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. CSS ──────────────────────────────────────────────────────────────────
CSS_DIR="$THEME_DIR/css"
mkdir -p "$CSS_DIR"
cp "$WORKSPACE/checkout.css" "$CSS_DIR/checkout.css"
echo "✓ checkout.css → $CSS_DIR/"

# ── 2. JavaScript ───────────────────────────────────────────────────────────
JS_DIR="$THEME_DIR/js"
mkdir -p "$JS_DIR"
cp "$WORKSPACE/checkout.js" "$JS_DIR/checkout.js"
echo "✓ checkout.js → $JS_DIR/"

# ── 3. Template ─────────────────────────────────────────────────────────────
LAYOUT_DIR="$THEME_DIR/templates/layout"
mkdir -p "$LAYOUT_DIR"
cp "$WORKSPACE/page--checkout.html.twig" "$LAYOUT_DIR/page--checkout.html.twig"
echo "✓ page--checkout.html.twig → $LAYOUT_DIR/"

# ── 4. Libraries YAML ───────────────────────────────────────────────────────
cp "$WORKSPACE/hivesticks.libraries.yml" "$THEME_DIR/${THEME}.libraries.yml"
echo "✓ ${THEME}.libraries.yml → $THEME_DIR/"

# ── 4. Preprocess hook (embeds order data for "In your cart" sidebar) ────────
#    Copies add-checkout-preprocess.php into the kartpro repo, runs it via
#    drush (so it has full Drupal bootstrap), then removes the temp copy.
#    The script detects the active theme and appends the hook only if missing.
PREPROCESS_SRC="$WORKSPACE/add-checkout-preprocess.php"
if [ -f "$PREPROCESS_SRC" ]; then
  cp "$PREPROCESS_SRC" "$DRUPAL_ROOT/add-checkout-preprocess.php"
  ddev drush php-script add-checkout-preprocess.php
  rm -f "$DRUPAL_ROOT/add-checkout-preprocess.php"
  echo "✓ Preprocess hook verified in ${THEME}.theme"
else
  echo "⚠ add-checkout-preprocess.php not found in workspace — skipping hook step"
fi

# ── 5. Checkout flow pane layout (payment pane → payment step) ───────────────
#    Moves the Payment Information pane off order_information and onto payment,
#    so the steps match the design: shipping on step 3, payment on step 4.
FLOW_SRC="$WORKSPACE/fix-checkout-flow.php"
if [ -f "$FLOW_SRC" ]; then
  cp "$FLOW_SRC" "$DRUPAL_ROOT/"
  ddev drush php-script fix-checkout-flow.php
  rm -f "$DRUPAL_ROOT/fix-checkout-flow.php"
  echo "✓ Checkout flow panes configured"
else
  echo "⚠ fix-checkout-flow.php not found — skipping flow config"
fi

# ── 6. Disable CSS aggregation (dev mode) ────────────────────────────────────
ddev drush config:set system.performance css.preprocess 0 -y 2>/dev/null
ddev drush config:set system.performance js.preprocess 0 -y 2>/dev/null
echo "✓ CSS/JS aggregation disabled"

# ── 7. Clear cache ───────────────────────────────────────────────────────────
ddev drush cr
echo "✓ Cache cleared"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done! Now:"
echo "  1. Visit your checkout page in browser"
echo "  2. Hard refresh: Ctrl+Shift+R"
echo "  3. Should see V3 design (white cards,"
echo "     shadows, honey buttons, step bar)"
echo "  4. 'In your cart' sidebar should show"
echo "     actual cart items — no blank block"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Verify all files landed ──────────────────────────────────────────────────
echo "Verifying deploy..."
for DEPLOYED in "$CSS_DIR/checkout.css" "$JS_DIR/checkout.js" "$LAYOUT_DIR/page--checkout.html.twig"; do
  if [ -f "$DEPLOYED" ]; then
    LINES=$(wc -l < "$DEPLOYED")
    echo "✓ $DEPLOYED ($LINES lines)"
  else
    echo "✗ MISSING: $DEPLOYED — something went wrong"
  fi
done

# Verify preprocess hook landed in theme file
THEME_FILE="$THEME_DIR/${THEME}.theme"
if [ -f "$THEME_FILE" ] && grep -q "preprocess_page__checkout" "$THEME_FILE"; then
  echo "✓ ${THEME}_preprocess_page__checkout() present in ${THEME}.theme"
else
  echo "⚠ Preprocess hook not found in ${THEME}.theme"
  echo "  Run manually: cp $WORKSPACE/add-checkout-preprocess.php ~/projects/kartpro/"
  echo "                ddev drush php-script add-checkout-preprocess.php"
fi
