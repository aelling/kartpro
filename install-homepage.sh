#!/bin/bash
# install-homepage.sh
# ───────────────────
# Deploys the HiveSticks homepage template, CSS, JS, and updated libraries
# definition into the custom theme.
#
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash install-homepage.sh

THEME_DIR="web/themes/custom/hivesticks"
SCRIPTS_DIR="$(pwd)/hivesticks-scripts"  # adjust if you keep scripts elsewhere

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — install homepage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Verify theme directory ────────────────────────────────────────────────
if [ ! -d "$THEME_DIR" ]; then
  echo "ERROR: Theme directory not found: $THEME_DIR"
  echo "       Run this script from ~/projects/kartpro."
  exit 1
fi

# ── 2. Copy page--front.html.twig ────────────────────────────────────────────
echo "1. Installing page--front.html.twig..."
mkdir -p "$THEME_DIR/templates/layout"
cp "$SCRIPTS_DIR/homepage.html.twig" "$THEME_DIR/templates/layout/page--front.html.twig"
echo "   ✓ Copied → templates/layout/page--front.html.twig"
echo ""

# ── 3. Copy homepage.css ─────────────────────────────────────────────────────
echo "2. Installing homepage.css..."
mkdir -p "$THEME_DIR/css"
cp "$SCRIPTS_DIR/homepage.css" "$THEME_DIR/css/homepage.css"
echo "   ✓ Copied → css/homepage.css"
echo ""

# ── 4. Copy homepage.js ──────────────────────────────────────────────────────
echo "3. Installing homepage.js..."
mkdir -p "$THEME_DIR/js"
cp "$SCRIPTS_DIR/homepage.js" "$THEME_DIR/js/homepage.js"
echo "   ✓ Copied → js/homepage.js"
echo ""

# ── 5. Also copy updated pdp.js (add-to-cart init fix) ──────────────────────
echo "4. Installing updated pdp.js (add-to-cart init fix)..."
cp "$SCRIPTS_DIR/pdp.js" "$THEME_DIR/js/pdp.js"
echo "   ✓ Copied → js/pdp.js"
echo ""

# ── 6. Copy updated libraries definition ─────────────────────────────────────
echo "5. Installing updated hivesticks.libraries.yml..."
cp "$SCRIPTS_DIR/hivesticks.libraries.yml" "$THEME_DIR/hivesticks.libraries.yml"
echo "   ✓ Copied → hivesticks.libraries.yml"
echo ""

# ── 7. Clear Drupal cache ────────────────────────────────────────────────────
echo "6. Clearing cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to check:"
echo ""
echo "  1. Visit https://kartpro.ddev.site/"
echo "     You should see the full homepage with nav, hero, sections, and footer."
echo ""
echo "  2. Scroll down — the nav should gain a background (is-scrolled class)."
echo ""
echo "  3. Click FAQ questions — they should open/close one at a time."
echo ""
echo "  4. Visit a product page and click Add to Cart without selecting a pack first."
echo "     It should now add to cart immediately (Commerce variation pre-selected)."
echo ""
echo "  If the homepage shows unstyled or missing sections:"
echo "    ddev drush cr && hard-refresh the browser (Shift+Reload)"
echo ""
