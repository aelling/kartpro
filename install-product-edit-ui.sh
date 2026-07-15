#!/bin/bash
# install-product-edit-ui.sh
# ───────────────────────────
# Installs the product page Twig template and admin edit bar CSS into your custom theme.
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash install-product-edit-ui.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

# ── 1. Discover the active custom theme ──────────────────────────────────────
echo "Detecting active custom theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | tr -d '[:space:]')

if [ -z "$THEME" ]; then
  echo "ERROR: Could not detect theme via drush. Is DDEV running? (ddev start)"
  exit 1
fi

# Search for the theme directory anywhere under themes/
THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)

if [ -z "$THEME_DIR" ]; then
  echo "ERROR: Theme directory not found for '$THEME' under $DRUPAL_ROOT/themes/"
  exit 1
fi

echo "  Theme: $THEME"
echo "  Path:  $THEME_DIR"
echo ""

# ── 2. Install the Twig template ─────────────────────────────────────────────
echo "Installing Twig template..."

TEMPLATES_DIR="$THEME_DIR/templates/commerce"
mkdir -p "$TEMPLATES_DIR"

cp "$WORKSPACE/commerce-product--honey-stick.html.twig" \
   "$TEMPLATES_DIR/commerce-product--honey-stick.html.twig"

echo "  ✓ commerce-product--honey-stick.html.twig → $TEMPLATES_DIR/"
echo ""

# ── 3. Add the admin bar CSS ─────────────────────────────────────────────────
echo "Adding admin bar CSS to theme stylesheet..."

# Find the main CSS file (tries common names)
CSS_FILE=""
for candidate in \
  "$THEME_DIR/css/style.css" \
  "$THEME_DIR/css/main.css" \
  "$THEME_DIR/css/app.css" \
  "$THEME_DIR/css/${THEME}.css" \
  "$THEME_DIR/${THEME}.css" \
  "$THEME_DIR/style.css"; do
  if [ -f "$candidate" ]; then
    CSS_FILE="$candidate"
    break
  fi
done

ADMIN_CSS="$WORKSPACE/product-admin-bar.css"

if [ -n "$CSS_FILE" ]; then
  # Check if it's already been added
  if grep -q "product-admin-bar" "$CSS_FILE"; then
    echo "  ✓ Admin bar CSS already present in $CSS_FILE — skipping."
  else
    echo "" >> "$CSS_FILE"
    echo "/* ── Product admin bar (injected by install-product-edit-ui.sh) ── */" >> "$CSS_FILE"
    cat "$ADMIN_CSS" >> "$CSS_FILE"
    echo "  ✓ Admin bar CSS appended to $CSS_FILE"
  fi
else
  # No existing CSS file found — copy as standalone and note it
  STANDALONE="$THEME_DIR/css/product-admin-bar.css"
  mkdir -p "$THEME_DIR/css"
  cp "$ADMIN_CSS" "$STANDALONE"
  echo "  ⚠ Could not find your main CSS file automatically."
  echo "    Copied standalone CSS to: $STANDALONE"
  echo "    Add it to your theme's .libraries.yml:"
  echo "      product-admin-bar:"
  echo "        css:"
  echo "          theme:"
  echo "            css/product-admin-bar.css: {}"
  echo "    Then reference it in your theme's .info.yml or attach it to the template."
fi

echo ""

# ── 4. Add preprocess hook to hivesticks.theme ───────────────────────────────
echo "Adding preprocess hook to ${THEME}.theme..."

THEME_PHP="$THEME_DIR/${THEME}.theme"

# Create the file if it doesn't exist yet
if [ ! -f "$THEME_PHP" ]; then
  echo "<?php" > "$THEME_PHP"
  echo "" >> "$THEME_PHP"
fi

PREPROCESS_FN="${THEME}_preprocess_commerce_product"

if grep -q "$PREPROCESS_FN" "$THEME_PHP"; then
  echo "  ✓ $PREPROCESS_FN already present — skipping."
else
  cat >> "$THEME_PHP" << 'PHPBLOCK'

/**
 * Prepares variables for commerce_product templates.
 *
 * Passes product_edit_url to Twig — NULL for shoppers, edit URL for admins.
 * (Calling ->access() directly in Twig is blocked by the sandbox.)
 */
function THEME_PLACEHOLDER_preprocess_commerce_product(&$variables) {
  /** @var \Drupal\commerce_product\Entity\ProductInterface $product */
  $product = $variables['elements']['#commerce_product'];
  $variables['product_edit_url'] = $product->access('update')
    ? $product->toUrl('edit-form')->toString()
    : NULL;
}
PHPBLOCK

  # Replace the placeholder with the real theme name
  sed -i "s/THEME_PLACEHOLDER/${THEME}/g" "$THEME_PHP"
  echo "  ✓ $PREPROCESS_FN added to $THEME_PHP"
fi

echo ""

# ── 6. Add tabs to page.html.twig (if not already present) ───────────────────
echo "Checking page.html.twig for tabs block..."

PAGE_TWIG=$(find "$THEME_DIR/templates" -name "page.html.twig" 2>/dev/null | head -1)

if [ -z "$PAGE_TWIG" ]; then
  echo "  ⚠ No page.html.twig found in theme templates."
  echo "    To add local task tabs (View | Edit), add this to your page template:"
  echo '    {% if page.tabs %}<nav class="tabs" role="navigation">{{ page.tabs }}</nav>{% endif %}'
else
  if grep -q "page.tabs" "$PAGE_TWIG"; then
    echo "  ✓ page.tabs already present in $PAGE_TWIG — nothing to do."
  else
    echo ""
    echo "  Found: $PAGE_TWIG"
    echo "  ── page.tabs is NOT in this template yet."
    echo "  Add the following line where you want View/Edit tabs to appear"
    echo "  (typically just below the header, before main content):"
    echo ""
    echo '    {% if page.tabs %}'
    echo '      <nav class="tabs" role="navigation" aria-label="Primary tabs">'
    echo '        {{ page.tabs }}'
    echo '      </nav>'
    echo '    {% endif %}'
    echo ""
    echo "  File to edit: $PAGE_TWIG"
  fi
fi

echo ""

# ── 7. Clear cache ────────────────────────────────────────────────────────────
echo "Clearing Drupal cache..."
ddev drush cr
echo ""
echo "Done! Visit any Honey Stick product page while logged in to see the Edit button."
