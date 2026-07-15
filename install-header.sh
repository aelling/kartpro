#!/bin/bash
# install-header.sh
# ─────────────────
# Deploys the HiveSticks header (logo + cart badge) to the custom theme.
#
# What this deploys:
#   • page.html.twig     — inner page wrapper (cart, PDP, etc.) with branded nav
#   • header.css         — nav styles, logo, cart badge (for inner pages)
#   • header.js          — sticky nav + cart badge fetch (for inner pages)
#   • homepage.html.twig — updated front page nav (logo img + cart icon)
#   • homepage.css       — updated with logo/badge additions
#   • homepage.js        — updated with cart badge fetch behavior
#   • hivesticks.libraries.yml — updated with 'header' library entry
#
# Usage:
#   bash install-header.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks Header — theme install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Find theme ──────────────────────────────────────────────────────────────
echo "1. Detecting active theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "   ERROR: Could not detect theme. Is DDEV running? (ddev start)"
  exit 1
fi
THEME_DIR=$(find "$DRUPAL_ROOT/web/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  # Try without /web/ prefix
  THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
fi
if [ -z "$THEME_DIR" ]; then
  echo "   ERROR: Theme directory not found for '$THEME'"
  exit 1
fi
echo "   Theme: $THEME → $THEME_DIR"
echo ""

# ── 2. Create directories ──────────────────────────────────────────────────────
mkdir -p "$THEME_DIR/templates/layout"
mkdir -p "$THEME_DIR/css"
mkdir -p "$THEME_DIR/js"

# ── 3. Inner page template ─────────────────────────────────────────────────────
# Deploy to both templates/ root AND templates/layout/ — Drupal discovers
# templates recursively and may pick either location; deploying to both
# ensures our version wins regardless of discovery order.
echo "2. Installing page.html.twig (inner page wrapper)..."
cp "$WORKSPACE/page.html.twig" "$THEME_DIR/templates/layout/page.html.twig"
cp "$WORKSPACE/page.html.twig" "$THEME_DIR/templates/page.html.twig"
echo "   ✓ page.html.twig → $THEME_DIR/templates/layout/"
echo "   ✓ page.html.twig → $THEME_DIR/templates/  (root, overrides any pre-existing)"
echo ""

# ── 4. Updated front page template (homepage) ─────────────────────────────────
echo "3. Installing updated homepage.html.twig (front page)..."
cp "$WORKSPACE/homepage.html.twig" "$THEME_DIR/templates/layout/page--front.html.twig"
cp "$WORKSPACE/homepage.html.twig" "$THEME_DIR/templates/page--front.html.twig"
echo "   ✓ homepage.html.twig → $THEME_DIR/templates/layout/page--front.html.twig"
echo "   ✓ homepage.html.twig → $THEME_DIR/templates/page--front.html.twig  (root)"
echo ""

# ── 5. Header CSS + JS ────────────────────────────────────────────────────────
echo "4. Installing header CSS/JS..."
cp "$WORKSPACE/header.css" "$THEME_DIR/css/header.css"
cp "$WORKSPACE/header.js"  "$THEME_DIR/js/header.js"
echo "   ✓ header.css → $THEME_DIR/css/"
echo "   ✓ header.js  → $THEME_DIR/js/"
echo ""

# ── 6. Updated homepage CSS + JS (logo/badge additions) ───────────────────────
echo "5. Installing updated homepage CSS/JS..."
cp "$WORKSPACE/homepage.css" "$THEME_DIR/css/homepage.css"
cp "$WORKSPACE/homepage.js"  "$THEME_DIR/js/homepage.js"
echo "   ✓ homepage.css → $THEME_DIR/css/"
echo "   ✓ homepage.js  → $THEME_DIR/js/"
echo ""

# ── 7. Libraries YAML ─────────────────────────────────────────────────────────
echo "6. Installing updated hivesticks.libraries.yml..."
cp "$WORKSPACE/hivesticks.libraries.yml" "$THEME_DIR/${THEME}.libraries.yml"
echo "   ✓ ${THEME}.libraries.yml → $THEME_DIR/"
echo ""

# ── 8. Clear Drupal cache ─────────────────────────────────────────────────────
echo "7. Clearing Drupal cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Upload your logo in Drupal:"
echo "     Appearance > Settings > HiveSticks > Logo image"
echo "     Upload the logo file and save."
echo ""
echo "  2. Check the cart badge:"
echo "     Add an item to the cart, then check the nav — should show a"
echo "     small dark circle badge with the item count."
echo ""
echo "     If the badge doesn't appear, check the browser console for"
echo "     CORS or 403 errors on /cart?_format=json"
echo "     The Commerce REST resource may need to be enabled:"
echo "       ddev drush en commerce_rest -y"
echo "       ddev drush cr"
echo ""
echo "  3. Visit the cart page — it should now have the branded nav:"
echo "     https://kartpro.ddev.site/cart"
echo ""
echo "  4. Visit the homepage — it should show the logo + cart badge too:"
echo "     https://kartpro.ddev.site/"
echo ""
