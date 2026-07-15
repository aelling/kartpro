#!/bin/bash
# apply-ui-changes.sh
# ───────────────────
# Applies three UI changes to the HiveSticks theme:
#   1. Restrict View/Edit/Delete (local task) tabs to the Administrator role only.
#   2. Remove the "Buy Now" (.hs-nav__cta) button from the header.
#   3. Show a "Go to cart" prompt after an item is added to the cart.
#
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash apply-ui-changes.sh

set -e

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — UI changes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Detect active theme ──────────────────────────────────────────────────
echo "1. Detecting active theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "   ERROR: Could not detect theme. Is DDEV running? (ddev start)"
  exit 1
fi
THEME_DIR=$(find "$DRUPAL_ROOT/web/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
fi
if [ -z "$THEME_DIR" ]; then
  echo "   ERROR: Theme directory not found for '$THEME'"
  exit 1
fi
echo "   Theme: $THEME → $THEME_DIR"
echo ""

# ── 2. Restrict local task tabs to Administrator role ───────────────────────
echo "2. Restricting View/Edit/Delete tabs to Administrator role..."
THEME_PHP="$THEME_DIR/${THEME}.theme"
if [ ! -f "$THEME_PHP" ]; then
  echo "<?php" > "$THEME_PHP"
  echo "" >> "$THEME_PHP"
fi

PREPROCESS_FN="${THEME}_preprocess_menu_local_tasks"
if grep -q "$PREPROCESS_FN" "$THEME_PHP"; then
  echo "   ✓ $PREPROCESS_FN already present — skipping."
else
  cat >> "$THEME_PHP" << 'PHPBLOCK'

/**
 * Implements hook_preprocess_menu_local_tasks().
 *
 * Hides the primary/secondary local task tabs (View | Edit | Delete, etc.)
 * from everyone except users in the 'administrator' role. This controls both
 * the {{ tabs }} template variable and the core "Tabs" block.
 */
function THEME_PLACEHOLDER_preprocess_menu_local_tasks(&$variables) {
  $account = \Drupal::currentUser();
  if (!in_array('administrator', $account->getRoles(), TRUE)) {
    $variables['primary'] = [];
    $variables['secondary'] = [];
  }
}
PHPBLOCK
  sed -i "s/THEME_PLACEHOLDER/${THEME}/g" "$THEME_PHP"
  echo "   ✓ $PREPROCESS_FN added to $THEME_PHP"
fi
echo ""

# ── 3. Remove the Buy Now button from header/page templates ─────────────────
# The header CTA may render as .hs-nav__cta OR as a plain <a>Buy Now</a> inside
# a page wrapper (e.g. page--commerce-product.html.twig). Remove both.
echo "3. Removing Buy Now button from theme templates..."
while IFS= read -r -d '' twig; do
  python3 - "$twig" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    html = f.read()
orig = html
# a) Any <a ...class="...hs-nav__cta...">...</a> element (may span lines).
html = re.sub(r'<a\b[^>]*hs-nav__cta[^>]*>.*?</a>\s*', '', html, flags=re.DOTALL)
# b) In page wrapper templates only, any <a> whose visible text is "Buy Now"
#    (covers a header CTA that doesn't use the hs-nav__cta class).
import os
base = os.path.basename(path)
if base.startswith("page"):
    html = re.sub(r'<a\b[^>]*>\s*\{?\{?\s*[\'"]?Buy Now[\'"]?[^<]*</a>\s*', '',
                  html, flags=re.DOTALL | re.IGNORECASE)
if html != orig:
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    print("   ✓ scrubbed Buy Now from:", path)
PYEOF
done < <(find "$THEME_DIR/templates" -name "*.html.twig" -print0 2>/dev/null)
echo "   (CSS also hides .hs-nav__cta as a safety net)"
echo ""

# ── 3b. Redeploy product template (admin tabs now gated to admins) ──────────
echo "3b. Redeploying product template (View/Edit/Delete tabs → admin only)..."
PROD_TPL_DIR="$THEME_DIR/templates/commerce"
mkdir -p "$PROD_TPL_DIR"
cp "$WORKSPACE/commerce-product--honey-stick.html.twig" \
   "$PROD_TPL_DIR/commerce-product--honey-stick.html.twig"
echo "   ✓ commerce-product--honey-stick.html.twig → $PROD_TPL_DIR/"
echo ""

# ── 4. Redeploy header CSS + JS (Buy Now hide + add-to-cart prompt) ─────────
echo "4. Redeploying header CSS/JS..."
mkdir -p "$THEME_DIR/css" "$THEME_DIR/js"
cp "$WORKSPACE/header.css" "$THEME_DIR/css/header.css"
cp "$WORKSPACE/header.js"  "$THEME_DIR/js/header.js"
echo "   ✓ header.css → $THEME_DIR/css/"
echo "   ✓ header.js  → $THEME_DIR/js/"
echo ""

# ── 5. Clear cache ──────────────────────────────────────────────────────────
echo "5. Clearing Drupal cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Verify:"
echo "  • Log in as a NON-admin (or view as anonymous) → View/Edit/Delete tabs gone."
echo "  • Log in as Administrator → tabs still visible."
echo "  • Header no longer shows the Buy Now button."
echo "  • Add a product to the cart → 'Go to cart' prompt appears top-right."
echo ""
