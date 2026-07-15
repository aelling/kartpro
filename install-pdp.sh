#!/bin/bash
# install-pdp.sh
# ──────────────
# Deploys all HiveSticks PDP assets to the custom theme.
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash install-pdp.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

# DDEV requires commands to run from inside the project directory
cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks PDP — theme install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Find theme ─────────────────────────────────────────────────────────────
echo "1. Detecting active theme..."
# Pipe through awk to grab only the last word — DDEV startup messages
# can pollute stdout, so we discard everything except the final token.
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

# ── 2. Twig template ──────────────────────────────────────────────────────────
echo "2. Installing Twig template..."
TWIG_DIR="$THEME_DIR/templates/commerce"
mkdir -p "$TWIG_DIR"
cp "$WORKSPACE/commerce-product--honey-stick.html.twig" "$TWIG_DIR/"
echo "   ✓ commerce-product--honey-stick.html.twig → $TWIG_DIR/"
echo ""

# ── 3. CSS ────────────────────────────────────────────────────────────────────
echo "3. Installing CSS..."
CSS_DIR="$THEME_DIR/css"
mkdir -p "$CSS_DIR"
cp "$WORKSPACE/pdp.css" "$CSS_DIR/pdp.css"
echo "   ✓ pdp.css → $CSS_DIR/"
echo ""

# ── 4. JS ─────────────────────────────────────────────────────────────────────
echo "4. Installing JS..."
JS_DIR="$THEME_DIR/js"
mkdir -p "$JS_DIR"
cp "$WORKSPACE/pdp.js" "$JS_DIR/pdp.js"
echo "   ✓ pdp.js → $JS_DIR/"
echo ""

# ── 5. Libraries YAML ─────────────────────────────────────────────────────────
echo "5. Installing hivesticks.libraries.yml..."
LIBRARIES_FILE="$THEME_DIR/${THEME}.libraries.yml"
cp "$WORKSPACE/hivesticks.libraries.yml" "$LIBRARIES_FILE"
echo "   ✓ ${THEME}.libraries.yml → $THEME_DIR/"
echo ""

# ── 6. Preprocess hook in hivesticks.theme ────────────────────────────────────
echo "6. Updating ${THEME}.theme preprocess hook..."
THEME_PHP="$THEME_DIR/${THEME}.theme"

if [ ! -f "$THEME_PHP" ]; then
  echo "<?php" > "$THEME_PHP"
  echo "" >> "$THEME_PHP"
fi

if grep -q "hivesticks_preprocess_commerce_product" "$THEME_PHP"; then
  echo "   ℹ Preprocess function already present — removing all versions..."
  # Use Python to reliably remove ALL occurrences of the function
  # (handles both the old short version and any marker-wrapped version)
  python3 - "$THEME_PHP" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
# Remove marker-wrapped block if present
content = re.sub(r'/\* HIVESTICKS-PREPROCESS-START \*/.*?/\* HIVESTICKS-PREPROCESS-END \*/', '', content, flags=re.DOTALL)
# Remove any remaining bare function declaration
content = re.sub(r'(/\*\*[^}]*?\*/\s*)?function hivesticks_preprocess_commerce_product\s*\([^)]*\)\s*\{[^}]*?\}\s*\n', '', content, flags=re.DOTALL)
with open(path, 'w') as f:
    f.write(content)
PYEOF
fi

cat >> "$THEME_PHP" << 'PHPBLOCK'

/* HIVESTICKS-PREPROCESS-START */
/**
 * Prepares variables for the Honey Stick commerce product template.
 *
 * Passes to Twig:
 *   product_edit_url — edit URL for users with update access; NULL otherwise
 *   highlight_items  — parsed from field_highlight (format: num|||title|||body)
 *   faq_items        — parsed from field_faq (format: question|||answer)
 *
 * Passes to drupalSettings (for JS pickers):
 *   hivesticks.flavors — flavor attribute values with swatch/notes data
 *   hivesticks.packs   — pack size attribute values with price/label data
 */
function hivesticks_preprocess_commerce_product(&$variables) {
  /** @var \Drupal\commerce_product\Entity\ProductInterface $product */
  $product = $variables['elements']['#commerce_product'];

  // ── Edit URL ──────────────────────────────────────────────────────────────
  $variables['product_edit_url'] = $product->access('update')
    ? $product->toUrl('edit-form')->toString()
    : NULL;

  // ── Highlights ────────────────────────────────────────────────────────────
  $variables['highlight_items'] = [];
  if ($product->hasField('field_highlight')) {
    foreach ($product->get('field_highlight') as $item) {
      $parts = explode('|||', $item->value, 3);
      if (count($parts) === 3) {
        $variables['highlight_items'][] = [
          'num'   => trim($parts[0]),
          'title' => trim($parts[1]),
          'body'  => trim($parts[2]),
        ];
      }
    }
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────
  $variables['faq_items'] = [];
  if ($product->hasField('field_faq')) {
    foreach ($product->get('field_faq') as $item) {
      $parts = explode('|||', $item->value, 2);
      if (count($parts) === 2) {
        $variables['faq_items'][] = [
          'question' => trim($parts[0]),
          'answer'   => trim($parts[1]),
        ];
      }
    }
  }

  // ── Pack size data → drupalSettings ──────────────────────────────────────
  // Only include pack sizes that have an actual variation on THIS product.
  // Walk the product's variations to collect pack_size AV IDs and prices.
  $price_by_pack = [];
  foreach ($product->getVariations() as $variation) {
    if (!$variation->hasField('attribute_pack_size')) continue;
    $pack_ref = $variation->get('attribute_pack_size');
    if ($pack_ref->isEmpty()) continue;
    $pack_av_id = (string) $pack_ref->target_id;
    if (!array_key_exists($pack_av_id, $price_by_pack)) {
      $price_obj = $variation->getPrice();
      $price_by_pack[$pack_av_id] = ($price_obj && (float) $price_obj->getNumber() > 0)
        ? $price_obj->getNumber() : 0;
    }
  }

  // Load those AV entities so we can get weights and custom fields.
  $pack_av_entities = \Drupal::entityTypeManager()
    ->getStorage('commerce_product_attribute_value')
    ->loadMultiple(array_keys($price_by_pack));
  uasort($pack_av_entities, fn($a, $b) => $a->getWeight() <=> $b->getWeight());

  $packs_data = [];
  foreach ($pack_av_entities as $av) {
    $packs_data[] = [
      'id'         => $av->id(),
      'count'      => $av->getName(),
      'price'      => $price_by_pack[(string) $av->id()] ?? 0,
      'per_stick'  => $av->hasField('field_pack_per_stick')  ? ($av->get('field_pack_per_stick')->value  ?? 0) : 0,
      'label'      => $av->hasField('field_pack_label')      ? ($av->get('field_pack_label')->value      ?? '') : '',
      'note'       => $av->hasField('field_pack_note')       ? ($av->get('field_pack_note')->value       ?? '') : '',
      'is_popular' => $av->hasField('field_pack_is_popular') ? (bool) $av->get('field_pack_is_popular')->value : FALSE,
      'save_label' => $av->hasField('field_pack_save_label') ? ($av->get('field_pack_save_label')->value ?? '') : '',
    ];
  }

  // Attach data to drupalSettings for JS pickers
  if (!empty($packs_data)) {
    $variables['#attached']['drupalSettings']['hivesticks'] = [
      'packs' => $packs_data,
    ];
  }

  // ── Add-to-cart form ──────────────────────────────────────────────────────
  // Render directly via viewField so we are not dependent on the 'full'
  // entity view display existing.  The 'default' display has the
  // commerce_add_to_cart formatter, and viewField uses it explicitly.
  try {
    $view_builder = \Drupal::entityTypeManager()->getViewBuilder('commerce_product');
    $variables['add_to_cart_form'] = $view_builder->viewField(
      $product->get('variations'),
      ['type' => 'commerce_add_to_cart', 'settings' => ['combine' => TRUE, 'quantity' => TRUE]]
    );
  }
  catch (\Exception $e) {
    $variables['add_to_cart_form'] = [];
  }
}
/* HIVESTICKS-PREPROCESS-END */
PHPBLOCK

echo "   ✓ Preprocess hook written to $THEME_PHP"
echo ""

# ── 7. Clear Drupal cache ─────────────────────────────────────────────────────
echo "7. Clearing Drupal cache..."
ddev drush cr
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to do next:"
echo ""
echo "  1. Run the fields script (if not done yet):"
echo "     bash add-pdp-fields.sh"
echo ""
echo "  2. Fill in Flavor attribute values with swatch colors:"
echo "     Commerce > Configuration > Product attributes > Flavor"
echo ""
echo "  3. Fill in Pack Size attribute value labels/notes:"
echo "     Commerce > Configuration > Product attributes > Pack Size"
echo ""
echo "  4. Edit your Honey Stick product and populate all the new fields."
echo "     Commerce > Products > [your product] > Edit"
echo ""
echo "  5. Visit the product page while logged in."
echo "     You should see the full PDP design with dynamic field values."
echo ""
