#!/bin/bash
# find-header.sh — locate whatever renders the site header + "Buy Now" button.
# Run:  cd ~/projects/kartpro && bash find-header.sh   (paste the whole output back)

ROOT="$HOME/projects/kartpro"
# Search everywhere meaningful, skip vendor/node_modules/core for speed.
SEARCH_DIRS=("$ROOT/web/themes" "$ROOT/web/modules" "$ROOT/config" "$ROOT/web/sites")

echo "══════════════════════════════════════════"
echo " Locating the header / Buy Now source"
echo "══════════════════════════════════════════"

echo "── A. Active theme + its base theme chain ──"
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
echo "   default theme: $THEME"
for info in $(find "$ROOT/web/themes" -name "*.info.yml" 2>/dev/null); do
  if grep -q "base theme" "$info"; then
    echo "   $(basename "$info"): $(grep 'base theme' "$info")"
  fi
done
echo ""

echo "── B. Files containing the nav label 'For Families' (unique to the header) ──"
grep -rln --include="*.twig" --include="*.html" --include="*.yml" --include="*.php" \
  "For Families" "${SEARCH_DIRS[@]}" 2>/dev/null || echo "   (none — header text may be in the database, not files)"
echo ""

echo "── C. Files containing 'Buy Now' (any case) ──"
grep -rlin "Buy Now" "${SEARCH_DIRS[@]}" 2>/dev/null || echo "   (none in files — likely a block/menu stored in the database)"
echo ""

echo "── D. Any page.html.twig anywhere under web/ ──"
find "$ROOT/web" -name "page*.html.twig" 2>/dev/null | grep -v "/core/" || echo "   (none outside core)"
echo ""

echo "── E. ALL twig templates in the active theme (full list) ──"
THEME_DIR=$(find "$ROOT/web/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
find "$THEME_DIR" -name "*.html.twig" 2>/dev/null | sed "s|$THEME_DIR/||" | sort
echo ""

echo "── F. Header/nav blocks placed in a region (Drupal block config) ──"
ddev drush config:status 2>/dev/null | head -1 >/dev/null
ls "$ROOT/config"/*/block.block.*.yml 2>/dev/null | xargs -r -n1 basename 2>/dev/null
echo "   Blocks whose region looks like a header:"
for f in "$ROOT/config"/*/block.block.*.yml; do
  [ -f "$f" ] || continue
  region=$(grep -E "^  region:" "$f" | awk '{print $2}')
  plugin=$(grep -E "^  plugin:" "$f" | awk '{print $2}')
  case "$region" in
    *header*|*nav*|*primary*|*top*) echo "   $(basename "$f")  region=$region plugin=$plugin" ;;
  esac
done
echo ""

echo "── G. Custom blocks (may hold a Buy Now button in their body) ──"
ddev drush ev '\$s=\Drupal::entityTypeManager()->getStorage("block_content"); foreach(\$s->loadMultiple() as \$b){ print \$b->id()."  |  ".\$b->label()."  |  ".\$b->bundle()."\n"; }' 2>/dev/null || echo "   (could not query block_content)"
echo ""
echo "Done. Paste everything above."
