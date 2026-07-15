#!/bin/bash
# add-sticky-field.sh
# Adds "Feature in sticky bar" boolean field to honey_stick product type,
# patches hivesticks.theme preprocess to load the featured product dynamically,
# and deploys the updated homepage Twig template.
#
# Usage (from WSL):
#   bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/add-sticky-field.sh

set -e

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
THEME="$HOME/projects/kartpro/themes/custom/hivesticks"
KARTPRO="$HOME/projects/kartpro"

echo "=== Step 1: Add field_sticky_featured to honey_stick product type ==="
cd "$KARTPRO"
ddev drush php-eval '
$storage_id = "commerce_product.field_sticky_featured";
if (!\Drupal\field\Entity\FieldStorageConfig::load($storage_id)) {
  \Drupal\field\Entity\FieldStorageConfig::create([
    "field_name"  => "field_sticky_featured",
    "entity_type" => "commerce_product",
    "type"        => "boolean",
    "cardinality" => 1,
  ])->save();
  echo "  Created field storage\n";
} else {
  echo "  Field storage already exists\n";
}

$field_id = "commerce_product.honey_stick.field_sticky_featured";
if (!\Drupal\field\Entity\FieldConfig::load($field_id)) {
  \Drupal\field\Entity\FieldConfig::create([
    "field_name"    => "field_sticky_featured",
    "entity_type"   => "commerce_product",
    "bundle"        => "honey_stick",
    "label"         => "Feature in sticky bar",
    "required"      => FALSE,
    "default_value" => [["value" => 0]],
  ])->save();
  echo "  Created field on honey_stick bundle\n";
} else {
  echo "  Field already exists on bundle\n";
}

// Add to default form display so it shows in the product edit form
$display = \Drupal\Core\Entity\Entity\EntityFormDisplay::load("commerce_product.honey_stick.default");
if ($display && !$display->getComponent("field_sticky_featured")) {
  $display->setComponent("field_sticky_featured", [
    "type"     => "boolean_checkbox",
    "settings" => ["display_label" => TRUE],
    "weight"   => 5,
  ])->save();
  echo "  Added to form display\n";
}
echo "Done.\n";
'

echo ""
echo "=== Step 2: Patch hivesticks.theme — add sticky bar preprocess logic ==="

THEME_FILE="$THEME/hivesticks.theme"

python3 << PYEOF
import re

path = "$THEME_FILE"
with open(path, 'r') as f:
    src = f.read()

# Old preprocess (just the catalog part)
old = r'function hivesticks_preprocess_page__front\(&\\\$variables\) \{.*?\}'

# Check if sticky bar code is already there
if 'field_sticky_featured' in src:
    print("  Preprocess already has sticky bar logic — skipping patch")
else:
    # Find the function and replace its body
    pattern = re.compile(
        r'(function hivesticks_preprocess_page__front\(&\\\$variables\) \{)(.*?)(\n\})',
        re.DOTALL
    )
    match = pattern.search(src)
    if not match:
        print("  ERROR: Could not find hivesticks_preprocess_page__front()")
        exit(1)

    new_body = r"""
  \$variables['#attached']['library'][] = 'hivesticks/homepage';

  // Catalog products for the shop section
  \$view = \Drupal\views\Views::getView('catalog');
  if (\$view) {
    \$variables['catalog_products'] = \$view->preview('default');
  }

  // Sticky bar: load the product with "Feature in sticky bar" checked
  \$product_storage = \Drupal::entityTypeManager()->getStorage('commerce_product');
  \$pids = \$product_storage->getQuery()
    ->condition('status', 1)
    ->condition('type', 'honey_stick')
    ->condition('field_sticky_featured', 1)
    ->sort('changed', 'DESC')
    ->range(0, 1)
    ->accessCheck(FALSE)
    ->execute();

  if (\$pids) {
    \$product = \$product_storage->load(reset(\$pids));
    \$variables['sticky_product_name'] = \$product->getTitle();
    \$variables['sticky_product_url']  = \$product->toUrl()->toString();

    // Find the minimum price across all variations
    \$min_price = NULL;
    foreach (\$product->getVariations() as \$variation) {
      \$price = \$variation->getPrice();
      if (\$price && (\$min_price === NULL || (float)\$price->getNumber() < (float)\$min_price->getNumber())) {
        \$min_price = \$price;
      }
    }
    if (\$min_price) {
      \$num = (float)\$min_price->getNumber();
      \$formatted = \$num == floor(\$num)
        ? '\$' . number_format(\$num, 0)
        : '\$' . number_format(\$num, 2);
      \$variables['sticky_product_price'] = 'From ' . \$formatted;
    }
  }
"""
    replacement = match.group(1) + new_body + match.group(3)
    new_src = src[:match.start()] + replacement + src[match.end():]
    with open(path, 'w') as f:
        f.write(new_src)
    print("  Patched hivesticks.theme OK")
PYEOF

echo ""
echo "=== Step 3: Deploy homepage.html.twig ==="
cp "$WORKSPACE/homepage.html.twig" "$THEME/templates/layout/page--front.html.twig"
echo "  Twig deployed"

echo ""
echo "=== Step 4: Deploy homepage.css ==="
cp "$WORKSPACE/homepage.css" "$THEME/css/homepage.css"
echo "  CSS deployed"

echo ""
echo "=== Step 5: Clear Drupal cache ==="
ddev drush cr
echo "  Cache cleared"

echo ""
echo "=== All done! ==="
echo "  Go to Commerce → Products, edit a Honey Stick product,"
echo "  and check 'Feature in sticky bar' to populate the bar."
