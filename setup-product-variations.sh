#!/bin/bash
# setup-product-variations.sh
# ───────────────────────────
# 1. Adds the Flavor attribute to the honey_stick_pack variation type (if missing)
# 2. Creates all Flavor × Pack Size variations on a given product
#
# Usage (from ~/projects/kartpro):
#   bash setup-product-variations.sh            # defaults to first honey_stick_pack product
#   bash setup-product-variations.sh 16         # run against product ID 16

PRODUCT_ID="${1:-}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — variation setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PHP_SCRIPT="$(pwd)/_setup-variations-tmp.php"

cat > "$PHP_SCRIPT" << PHPEOF
<?php

use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\commerce_price\Price;
use Drupal\Core\Entity\Display\EntityFormDisplayInterface;

\$em = \Drupal::entityTypeManager();
\$av_storage = \$em->getStorage('commerce_product_attribute_value');
\$var_storage = \$em->getStorage('commerce_product_variation');
\$product_storage = \$em->getStorage('commerce_product');

// ═══════════════════════════════════════════════════════════════════
// 1. Add attribute_flavor field to honey_stick_pack variation type
// ═══════════════════════════════════════════════════════════════════
echo "\n1. Checking attribute_flavor on honey_stick_pack variation type...\n";

\$field_storage = FieldStorageConfig::loadByName('commerce_product_variation', 'attribute_flavor');
if (!\$field_storage) {
  \$field_storage = FieldStorageConfig::create([
    'field_name'   => 'attribute_flavor',
    'entity_type'  => 'commerce_product_variation',
    'type'         => 'entity_reference',
    'settings'     => ['target_type' => 'commerce_product_attribute_value'],
    'cardinality'  => 1,
    'translatable' => TRUE,
  ]);
  \$field_storage->save();
  echo "   ✓ Field storage created\n";
} else {
  echo "   · Field storage already exists\n";
}

\$field_config = FieldConfig::loadByName('commerce_product_variation', 'honey_stick_pack', 'attribute_flavor');
if (!\$field_config) {
  \$field_config = FieldConfig::create([
    'field_storage' => \$field_storage,
    'bundle'        => 'honey_stick_pack',
    'label'         => 'Flavor',
    'required'      => FALSE,
    'settings'      => [
      'handler'          => 'default:commerce_product_attribute_value',
      'handler_settings' => [
        'target_bundles' => ['flavor'],
        'auto_create'    => FALSE,
        'sort'           => ['field' => 'weight', 'direction' => 'ASC'],
      ],
    ],
  ]);
  \$field_config->save();
  echo "   ✓ Field config created for honey_stick_pack bundle\n";
} else {
  echo "   · Field config already exists\n";
}

// Add to form display so it shows on the variation edit form
\$form_display = \Drupal::service('entity_display.repository')
  ->getFormDisplay('commerce_product_variation', 'honey_stick_pack', 'default');
if (!\$form_display->getComponent('attribute_flavor')) {
  \$form_display->setComponent('attribute_flavor', [
    'type'     => 'commerce_product_variation_attributes',
    'weight'   => 0,
    'settings' => [],
  ]);
  \$form_display->save();
  echo "   ✓ Added to form display\n";
}

// ═══════════════════════════════════════════════════════════════════
// 2. Find target product
// ═══════════════════════════════════════════════════════════════════
echo "\n2. Finding target product...\n";

\$product_id = '${PRODUCT_ID}';
if (\$product_id) {
  \$product = \$product_storage->load(\$product_id);
  if (!\$product) {
    echo "   ERROR: Product \$product_id not found or not a honey_stick_pack type.\n";
    exit(1);
  }
} else {
  // Try both known product type names
  \$products = \$product_storage->loadByProperties(['type' => 'honey_stick']);
  if (empty(\$products)) {
    \$products = \$product_storage->loadByProperties(['type' => 'honey_stick_pack']);
  }
  if (empty(\$products)) {
    echo "   ERROR: No honey_stick_pack products found. Create one first.\n";
    exit(1);
  }
  \$product = reset(\$products);
}

echo "   Using: " . \$product->label() . " (ID " . \$product->id() . ")\n";

// ═══════════════════════════════════════════════════════════════════
// 3. Load attribute values
// ═══════════════════════════════════════════════════════════════════
echo "\n3. Loading attribute values...\n";

\$flavor_avs = \$av_storage->loadByProperties(['attribute' => 'flavor']);
\$pack_avs   = \$av_storage->loadByProperties(['attribute' => 'pack_size']);

uasort(\$flavor_avs, fn(\$a, \$b) => \$a->getWeight() <=> \$b->getWeight());
uasort(\$pack_avs,   fn(\$a, \$b) => \$a->getWeight() <=> \$b->getWeight());

echo "   " . count(\$flavor_avs) . " flavor(s): " . implode(', ', array_map(fn(\$a) => \$a->getName(), \$flavor_avs)) . "\n";
echo "   " . count(\$pack_avs)   . " pack(s):   " . implode(', ', array_map(fn(\$a) => \$a->getName(), \$pack_avs)) . "\n";

// ═══════════════════════════════════════════════════════════════════
// 4. Price map by pack size name
// ═══════════════════════════════════════════════════════════════════
\$price_map = [
  '20 Sticks'    => '8.99',
  '30 Sticks'    => '12.99',
  '50 Sticks'    => '19.99',
  '100 Sticks'   => '34.99',
  'Variety Pack' => '12.99',
];

// SKU abbreviations
\$flavor_sku_map = [
  'Wildflower'     => 'WILD',
  'Clover'         => 'CLOV',
  'Buckwheat'      => 'BUCK',
  'Cinnamon'       => 'CINN',
  'Lemon Ginger'   => 'LGNG',
  'Orange Blossom' => 'ORBL',
  'Lavender'       => 'LAVD',
];
\$pack_sku_map = [
  '20 Sticks'    => '20',
  '30 Sticks'    => '30',
  '50 Sticks'    => '50',
  '100 Sticks'   => '100',
  'Variety Pack' => 'VAR',
];

// ═══════════════════════════════════════════════════════════════════
// 5. Build existing variation index (SKU → variation) to avoid dupes
// ═══════════════════════════════════════════════════════════════════
\$existing = [];
foreach (\$product->getVariations() as \$v) {
  \$existing[\$v->getSku()] = \$v;
}

echo "\n4. Creating variations...\n";

\$created = 0;
\$skipped = 0;

foreach (\$flavor_avs as \$flavor_av) {
  \$fname = \$flavor_av->getName();
  \$fsku  = \$flavor_sku_map[\$fname] ?? strtoupper(substr(preg_replace('/[^a-z]/i', '', \$fname), 0, 4));

  foreach (\$pack_avs as \$pack_av) {
    \$pname = \$pack_av->getName();
    \$psku  = \$pack_sku_map[\$pname] ?? strtoupper(substr(preg_replace('/[^a-z0-9]/i', '', \$pname), 0, 3));
    \$price = \$price_map[\$pname] ?? '9.99';
    \$sku   = \$fsku . '-' . \$psku;

    if (isset(\$existing[\$sku])) {
      // Update flavor attribute on existing variation if missing
      \$v = \$existing[\$sku];
      if (!\$v->get('attribute_flavor')->target_id) {
        \$v->set('attribute_flavor', \$flavor_av->id());
        \$v->save();
        echo "   ↻ Updated flavor on existing: \$sku\n";
      } else {
        echo "   · Skipping (exists): \$sku\n";
      }
      \$skipped++;
      continue;
    }

    \$variation = \$var_storage->create([
      'type'              => 'honey_stick_pack',
      'sku'               => \$sku,
      'price'             => new Price(\$price, 'USD'),
      'attribute_flavor'  => \$flavor_av->id(),
      'attribute_pack_size' => \$pack_av->id(),
      'status'            => 1,
    ]);
    \$variation->save();
    \$product->addVariation(\$variation);
    echo "   ✓ Created: \$sku  (\$fname / \$pname @ \\\$\$price)\n";
    \$created++;
  }
}

\$product->save();

echo "\n";
echo "   Created: \$created  |  Skipped: \$skipped\n";

// ═══════════════════════════════════════════════════════════════════
// 6. Update add-to-cart form display to show attributes properly
// ═══════════════════════════════════════════════════════════════════
echo "\n5. Updating add-to-cart form display...\n";

\$order_form_display = \Drupal::service('entity_display.repository')
  ->getFormDisplay('commerce_product_variation', 'honey_stick_pack', 'add_to_cart');
if (!\$order_form_display->getComponent('attribute_flavor')) {
  \$order_form_display->setComponent('attribute_flavor', [
    'type'     => 'commerce_product_variation_attributes',
    'weight'   => 0,
    'settings' => [],
  ]);
  \$order_form_display->save();
  echo "   ✓ attribute_flavor added to add-to-cart form display\n";
} else {
  echo "   · Already on add-to-cart form display\n";
}

echo "\nDone.\n";
PHPEOF

echo "Running via drush..."
ddev drush php:script _setup-variations-tmp.php
rm -f "$PHP_SCRIPT"

echo ""
echo "Clearing cache..."
ddev drush cr

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to check:"
echo "  1. Visit the product page — both Flavor and Pack Size"
echo "     selectors should now appear in the Commerce form."
echo "  2. The flavor swatch picker and pack card picker (built by JS)"
echo "     will now sync to those Commerce selects when clicked."
echo "  3. Prices are set to placeholder values — update them at:"
echo "     Commerce > Products > [product] > Edit > Variations tab"
echo ""
echo "Pack size prices used:"
echo "  20 Sticks  → \$8.99"
echo "  30 Sticks  → \$12.99"
echo "  50 Sticks  → \$19.99"
echo "  100 Sticks → \$34.99"
echo ""
echo "To run against a specific product ID:"
echo "  bash setup-product-variations.sh 16"
echo ""
