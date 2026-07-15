#!/bin/bash
# deploy-fix.sh — deploys ALL three UI changes to the LIVE theme directory.
# Root cause of prior failures: the site's docroot is the project root, so the
# active theme is at ~/projects/kartpro/themes/custom/hivesticks — NOT web/themes.
# Earlier scripts wrote to web/themes (a dead duplicate). This targets the real one.
#   cd ~/projects/kartpro && bash deploy-fix.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — deploy to the LIVE theme"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Determine the REAL theme path Drupal uses (relative to Drupal root) ──────
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then
  THEME_DIR="$DRUPAL_ROOT/$REL"
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then
  THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"   # confirmed-live fallback
else
  THEME_DIR=$(find "$DRUPAL_ROOT" -path "*/themes/*/$THEME" -name "$THEME" -type d 2>/dev/null | grep -v "/web/themes/" | head -1)
fi
if [ -z "$THEME_DIR" ] || [ ! -d "$THEME_DIR" ]; then
  echo "ERROR: could not locate the live theme dir."; exit 1
fi
echo "Live theme dir: $THEME_DIR"
echo ""

mkdir -p "$THEME_DIR/css" "$THEME_DIR/js" "$THEME_DIR/templates/commerce"

# ── 1. header.css + header.js (Buy Now hide, toast styles, ATC prompt) ──────
echo "1. Deploying header.css + header.js..."
cp "$WORKSPACE/header.css" "$THEME_DIR/css/header.css" && echo "   ✓ css/header.css"
cp "$WORKSPACE/header.js"  "$THEME_DIR/js/header.js"   && echo "   ✓ js/header.js"
echo ""

# ── 2. Product template (admin tabs gated to admins) ────────────────────────
echo "2. Deploying product template..."
DEST=$(find "$THEME_DIR/templates" -name "commerce-product--honey-stick.html.twig" 2>/dev/null | head -1)
[ -z "$DEST" ] && DEST="$THEME_DIR/templates/commerce/commerce-product--honey-stick.html.twig"
cp "$WORKSPACE/commerce-product--honey-stick.html.twig" "$DEST" && echo "   ✓ ${DEST#$THEME_DIR/}"
echo ""

# ── 3. Ensure both preprocess hooks exist in the LIVE .theme ────────────────
echo "3. Ensuring preprocess hooks in ${THEME}.theme..."
THEME_PHP="$THEME_DIR/${THEME}.theme"
[ -f "$THEME_PHP" ] || printf "<?php\n\n" > "$THEME_PHP"

if ! grep -q "${THEME}_preprocess_menu_local_tasks" "$THEME_PHP"; then
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Hide View/Edit/Delete local tasks for non-administrators.
 */
function THEME_preprocess_menu_local_tasks(&$variables) {
  if (!in_array('administrator', \Drupal::currentUser()->getRoles(), TRUE)) {
    $variables['primary'] = [];
    $variables['secondary'] = [];
  }
}
PHP
  sed -i "s/THEME_preprocess_menu_local_tasks/${THEME}_preprocess_menu_local_tasks/g" "$THEME_PHP"
  echo "   ✓ added menu_local_tasks hook"
else
  echo "   ✓ menu_local_tasks hook already present"
fi

if ! grep -q "${THEME}_preprocess_commerce_product" "$THEME_PHP"; then
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Provide product_edit_url only to users with update access (admins).
 * The product template shows the View/Edit/Delete bar only when this is set.
 */
function THEME_preprocess_commerce_product(&$variables) {
  $product = $variables['elements']['#commerce_product'];
  $variables['product_edit_url'] = $product->access('update')
    ? $product->toUrl('edit-form')->toString() : NULL;
}
PHP
  sed -i "s/THEME_preprocess_commerce_product/${THEME}_preprocess_commerce_product/g" "$THEME_PHP"
  echo "   ✓ added commerce_product preprocess (product_edit_url)"
else
  echo "   ✓ commerce_product preprocess already present"
fi
echo ""

# ── 4. Scrub the Buy Now anchor out of the live templates (belt + suspenders) ─
echo "4. Scrubbing Buy Now (.hs-nav__cta) from live templates..."
while IFS= read -r -d '' twig; do
  python3 - "$twig" << 'PY'
import re,sys
p=sys.argv[1]; s=open(p,encoding="utf-8").read()
n=re.sub(r'<a\b[^>]*hs-nav__cta[^>]*>.*?</a>\s*','',s,flags=re.DOTALL)
if n!=s:
    open(p,"w",encoding="utf-8").write(n); print("   ✓ scrubbed",p.split("/templates/")[-1])
PY
done < <(find "$THEME_DIR/templates" -name "*.html.twig" -print0 2>/dev/null)
echo "   (header.css also hides .hs-nav__cta as a safety net)"
echo ""

# ── 5. Clear caches ─────────────────────────────────────────────────────────
echo "5. Clearing Drupal cache..."
ddev drush cr
echo ""
echo "Done. Hard-refresh (Ctrl+Shift+R). Buy Now should be gone, the add-to-cart"
echo "prompt should appear, and View/Edit/Delete should show only for admins."
