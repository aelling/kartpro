#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  install-homepage-v2.sh
#  Deploys the new homepage design to the hivesticks DDEV theme.
#
#  Run from WSL:
#    bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/install-homepage-v2.sh
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
THEME_ROOT="$HOME/projects/kartpro/themes/custom/hivesticks"
LAYOUT_DIR="$THEME_ROOT/templates/layout"
JS_DIR="$THEME_ROOT/js"
CSS_DIR="$THEME_ROOT/css"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  HiveSticks Homepage v2 — Deploy             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Sanity check ───────────────────────────────────────────────────────
if [ ! -d "$THEME_ROOT" ]; then
  echo "❌  Theme directory not found: $THEME_ROOT"
  exit 1
fi

# ── Step 1: Copy Twig template ─────────────────────────────────────────
echo "▸ Step 1: Copying homepage.html.twig → page--front.html.twig"
mkdir -p "$LAYOUT_DIR"
cp "$WORKSPACE/homepage.html.twig" "$LAYOUT_DIR/page--front.html.twig"
echo "  ✓ $LAYOUT_DIR/page--front.html.twig"

# ── Step 2: Copy CSS ───────────────────────────────────────────────────
echo "▸ Step 2: Copying homepage.css"
mkdir -p "$CSS_DIR"
cp "$WORKSPACE/homepage.css" "$CSS_DIR/homepage.css"
echo "  ✓ $CSS_DIR/homepage.css"

# ── Step 3: Copy JS ────────────────────────────────────────────────────
echo "▸ Step 3: Copying homepage.js"
mkdir -p "$JS_DIR"
cp "$WORKSPACE/homepage.js" "$JS_DIR/homepage.js"
echo "  ✓ $JS_DIR/homepage.js"

# ── Step 4: Verify library declaration exists ──────────────────────────
echo "▸ Step 4: Checking library declaration"
LIBRARIES_FILE="$THEME_ROOT/hivesticks.libraries.yml"
if grep -q "homepage:" "$LIBRARIES_FILE" 2>/dev/null; then
  echo "  ✓ hivesticks/homepage library already declared"
else
  echo "  ⚠  'homepage:' not found in $LIBRARIES_FILE"
  echo "     Add the following to hivesticks.libraries.yml:"
  echo ""
  echo "     homepage:"
  echo "       version: 2.0"
  echo "       css:"
  echo "         theme:"
  echo "           css/homepage.css: {}"
  echo "       js:"
  echo "         js/homepage.js: {}"
  echo "       dependencies:"
  echo "         - core/drupal"
  echo "         - core/once"
fi

# ── Step 5: Clear Drupal caches ────────────────────────────────────────
echo "▸ Step 5: Clearing Drupal caches (ddev drush cr)"
cd "$HOME/projects/kartpro"
ddev drush cr
echo "  ✓ Caches cleared"

# ── Done ──────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ Homepage v2 deployed successfully!       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Open:  https://kartpro.ddev.site/"
echo ""
echo "  Quick checks:"
echo "  • Hero: two columns — headline left, product stage card right"
echo "  • Pack buttons (12/30/60/120) click to update price"
echo "  • Scroll down → sticky buy bar slides up from bottom"
echo "  • FAQ accordions open/close"
echo "  • Honey sticks fan SVG renders in hero card visual"
echo ""
