#!/bin/bash
# add-pdp-fields.sh
# ──────────────────
# Adds ALL fields required for the full HiveSticks PDP design.
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash add-pdp-fields.sh
#
# Sections:
#   A. Create Flavor product attribute + swatch/notes fields on attribute values
#   B. Add editorial fields to Pack Size attribute values
#   C. Add all new fields to the Honey Stick product type

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks PDP field setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── A. Flavor attribute ───────────────────────────────────────────────────────

echo "A. Setting up Flavor attribute..."

ddev drush php:eval "
use Drupal\commerce_product\Entity\ProductAttribute;
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\Entity\EntityFormDisplay;
use Drupal\Core\Entity\Entity\EntityViewDisplay;

// Create Flavor attribute if it doesn't exist
\$attr = ProductAttribute::load('flavor');
if (!\$attr) {
  \$attr = ProductAttribute::create(['id' => 'flavor', 'label' => 'Flavor']);
  \$attr->save();
  echo '  Created Flavor attribute' . PHP_EOL;
} else {
  echo '  Flavor attribute already exists' . PHP_EOL;
}

// Helper: create field on attribute values if not exists
\$entity_type = 'commerce_product_attribute_value';
\$bundle = 'flavor';

\$fields = [
  ['field_name' => 'field_swatch_color',
   'type'       => 'string',
   'label'      => 'Swatch Color (hex)',
   'desc'       => 'Primary swatch hex, e.g. #f0a929'],
  ['field_name' => 'field_swatch_deep',
   'type'       => 'string',
   'label'      => 'Swatch Deep (hex)',
   'desc'       => 'Darker shade hex, e.g. #c8851a'],
  ['field_name' => 'field_flavor_notes',
   'type'       => 'string',
   'label'      => 'Flavor Notes',
   'desc'       => 'e.g. Floral · Honeysuckle · Light'],
  ['field_name' => 'field_flavor_tagline',
   'type'       => 'string',
   'label'      => 'Flavor Tagline',
   'desc'       => 'e.g. Our signature. Bright, balanced, classic.'],
];

foreach (\$fields as \$i => \$f) {
  if (!FieldStorageConfig::loadByName(\$entity_type, \$f['field_name'])) {
    FieldStorageConfig::create([
      'field_name'  => \$f['field_name'],
      'entity_type' => \$entity_type,
      'type'        => \$f['type'],
      'cardinality' => 1,
    ])->save();
  }
  if (!FieldConfig::loadByName(\$entity_type, \$bundle, \$f['field_name'])) {
    FieldConfig::create([
      'field_storage' => FieldStorageConfig::loadByName(\$entity_type, \$f['field_name']),
      'bundle'        => \$bundle,
      'label'         => \$f['label'],
      'description'   => \$f['desc'],
    ])->save();
    echo '  Created ' . \$f['field_name'] . ' on flavor attribute' . PHP_EOL;
  } else {
    echo '  ' . \$f['field_name'] . ' already exists' . PHP_EOL;
  }

  // Add to form display
  \$fd = EntityFormDisplay::load(\$entity_type . '.' . \$bundle . '.default');
  if (\$fd && !\$fd->getComponent(\$f['field_name'])) {
    \$fd->setComponent(\$f['field_name'], ['type' => 'string_textfield', 'weight' => \$i + 10])->save();
  }
}
echo '  Flavor attribute: done' . PHP_EOL;
"

echo ""
echo "B. Adding fields to Pack Size attribute values..."

ddev drush php:eval "
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\Entity\EntityFormDisplay;

\$entity_type = 'commerce_product_attribute_value';
\$bundle = 'pack_size'; // Machine name of Pack Size attribute

// Check the attribute exists
\$attr = \Drupal\commerce_product\Entity\ProductAttribute::load(\$bundle);
if (!\$attr) {
  echo 'ERROR: pack_size attribute not found. Check the machine name.' . PHP_EOL;
  return;
}

\$fields = [
  ['field_name' => 'field_pack_label',
   'type'       => 'string',
   'label'      => 'Pack Label',
   'desc'       => 'e.g. Standard, Try Pack, Family, Bulk'],
  ['field_name' => 'field_pack_note',
   'type'       => 'string',
   'label'      => 'Pack Note',
   'desc'       => 'e.g. ~1 month, 7-day taste'],
  ['field_name' => 'field_pack_per_stick',
   'type'       => 'decimal',
   'label'      => 'Price Per Stick',
   'desc'       => 'e.g. 0.67'],
  ['field_name' => 'field_pack_is_popular',
   'type'       => 'boolean',
   'label'      => 'Is Popular?',
   'desc'       => 'Shows POPULAR badge on this pack'],
  ['field_name' => 'field_pack_save_label',
   'type'       => 'string',
   'label'      => 'Save Label',
   'desc'       => 'e.g. 10%, 20% — leave blank if no discount'],
];

foreach (\$fields as \$i => \$f) {
  \$settings = [];
  if (\$f['type'] === 'decimal') {
    \$settings = ['precision' => 10, 'scale' => 2];
  }
  if (!FieldStorageConfig::loadByName(\$entity_type, \$f['field_name'])) {
    FieldStorageConfig::create([
      'field_name'  => \$f['field_name'],
      'entity_type' => \$entity_type,
      'type'        => \$f['type'],
      'cardinality' => 1,
      'settings'    => \$settings,
    ])->save();
  }
  if (!FieldConfig::loadByName(\$entity_type, \$bundle, \$f['field_name'])) {
    FieldConfig::create([
      'field_storage' => FieldStorageConfig::loadByName(\$entity_type, \$f['field_name']),
      'bundle'        => \$bundle,
      'label'         => \$f['label'],
      'description'   => \$f['desc'],
    ])->save();
    echo '  Created ' . \$f['field_name'] . PHP_EOL;
  } else {
    echo '  ' . \$f['field_name'] . ' already exists' . PHP_EOL;
  }
  \$fd = EntityFormDisplay::load(\$entity_type . '.' . \$bundle . '.default');
  if (\$fd && !\$fd->getComponent(\$f['field_name'])) {
    \$widget = \$f['type'] === 'boolean' ? 'boolean_checkbox' : 'string_textfield';
    \$fd->setComponent(\$f['field_name'], ['type' => \$widget, 'weight' => \$i + 10])->save();
  }
}
echo '  Pack Size attribute: done' . PHP_EOL;
"

echo ""
echo "C. Adding product-level fields to Honey Stick..."

ddev drush php:eval "
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\Entity\EntityFormDisplay;
use Drupal\Core\Entity\Entity\EntityViewDisplay;

\$entity_type = 'commerce_product';
\$bundle = 'honey_stick';

\$string_fields = [
  // [field_name, label, description, weight]
  ['field_subtitle',       'Subtitle',            'Short tagline below title, e.g. Single-serve raw honey from our Iowa apiary...', 5],
  ['field_net_weight',     'Net Weight',          'e.g. 7 g per stick', 20],
  ['field_origin',         'Origin',              'e.g. Story County, Iowa, USA', 21],
  ['field_harvest',        'Harvest',             'e.g. May 2026 batch', 22],
  ['field_shelf_life',     'Shelf Life',          'e.g. 2 years; honey does not spoil', 23],
  ['field_storage',        'Storage',             'e.g. Room temp. May crystallize — warm to liquefy.', 24],
  ['field_allergens',      'Allergens',           'e.g. None. Made in honey-only facility.', 25],
  ['field_certifications', 'Certifications',      'e.g. USDA True Source · Non-GMO', 26],
];

foreach (\$string_fields as \$f) {
  if (!FieldStorageConfig::loadByName(\$entity_type, \$f[0])) {
    FieldStorageConfig::create([
      'field_name'  => \$f[0],
      'entity_type' => \$entity_type,
      'type'        => 'string',
      'cardinality' => 1,
    ])->save();
  }
  if (!FieldConfig::loadByName(\$entity_type, \$bundle, \$f[0])) {
    FieldConfig::create([
      'field_storage' => FieldStorageConfig::loadByName(\$entity_type, \$f[0]),
      'bundle'  => \$bundle,
      'label'   => \$f[1],
      'description' => \$f[2],
    ])->save();
    echo '  Created ' . \$f[0] . PHP_EOL;
  } else {
    echo '  ' . \$f[0] . ' already exists' . PHP_EOL;
  }
  \$fd = EntityFormDisplay::load(\$entity_type . '.' . \$bundle . '.default');
  if (\$fd && !\$fd->getComponent(\$f[0])) {
    \$fd->setComponent(\$f[0], ['type' => 'string_textfield', 'weight' => \$f[3]])->save();
  }
  \$vd = EntityViewDisplay::load(\$entity_type . '.' . \$bundle . '.default');
  if (\$vd && !\$vd->getComponent(\$f[0])) {
    \$vd->setComponent(\$f[0], ['type' => 'string', 'label' => 'hidden', 'weight' => \$f[3]])->save();
  }
}
echo '  String fields: done' . PHP_EOL;
"

ddev drush php:eval "
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\Entity\EntityFormDisplay;
use Drupal\Core\Entity\Entity\EntityViewDisplay;

\$entity_type = 'commerce_product';
\$bundle = 'honey_stick';

// Rating (decimal)
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_rating')) {
  FieldStorageConfig::create(['field_name' => 'field_rating', 'entity_type' => \$entity_type,
    'type' => 'decimal', 'cardinality' => 1, 'settings' => ['precision' => 4, 'scale' => 1]])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_rating')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_rating'),
    'bundle' => \$bundle, 'label' => 'Star Rating', 'description' => 'e.g. 4.9'])->save();
  echo '  Created field_rating' . PHP_EOL;
}

// Review count (integer)
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_review_count')) {
  FieldStorageConfig::create(['field_name' => 'field_review_count', 'entity_type' => \$entity_type,
    'type' => 'integer', 'cardinality' => 1])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_review_count')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_review_count'),
    'bundle' => \$bundle, 'label' => 'Review Count', 'description' => 'e.g. 1284'])->save();
  echo '  Created field_review_count' . PHP_EOL;
}

// Orders this month (integer)
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_orders_this_month')) {
  FieldStorageConfig::create(['field_name' => 'field_orders_this_month', 'entity_type' => \$entity_type,
    'type' => 'integer', 'cardinality' => 1])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_orders_this_month')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_orders_this_month'),
    'bundle' => \$bundle, 'label' => 'Orders This Month', 'description' => 'e.g. 4200 (shows as 4,200+ orders this month)'])->save();
  echo '  Created field_orders_this_month' . PHP_EOL;
}

// Long description body (text_long)
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_description_body')) {
  FieldStorageConfig::create(['field_name' => 'field_description_body', 'entity_type' => \$entity_type,
    'type' => 'text_long', 'cardinality' => 1])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_description_body')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_description_body'),
    'bundle' => \$bundle, 'label' => 'Description Body',
    'description' => 'The longer product description shown in the Details tab.'])->save();
  echo '  Created field_description_body' . PHP_EOL;
}

// Highlights (string_long, cardinality 4)
// Format each value as: 01|||Just honey|||No HFCS, no syrup, no flavoring fillers.
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_highlight')) {
  FieldStorageConfig::create(['field_name' => 'field_highlight', 'entity_type' => \$entity_type,
    'type' => 'string_long', 'cardinality' => 4])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_highlight')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_highlight'),
    'bundle' => \$bundle, 'label' => 'Highlights',
    'description' => 'Up to 4 items. Format each as: 01|||Title|||Description text'])->save();
  echo '  Created field_highlight' . PHP_EOL;
}

// FAQ (string_long, cardinality unlimited)
// Format each value as: Question text|||Answer text
if (!FieldStorageConfig::loadByName(\$entity_type, 'field_faq')) {
  FieldStorageConfig::create(['field_name' => 'field_faq', 'entity_type' => \$entity_type,
    'type' => 'string_long', 'cardinality' => -1])->save();
}
if (!FieldConfig::loadByName(\$entity_type, \$bundle, 'field_faq')) {
  FieldConfig::create(['field_storage' => FieldStorageConfig::loadByName(\$entity_type, 'field_faq'),
    'bundle' => \$bundle, 'label' => 'FAQ Items',
    'description' => 'One per item. Format: Question|||Answer'])->save();
  echo '  Created field_faq' . PHP_EOL;
}

// Add numeric/text fields to form display
\$fd = EntityFormDisplay::load(\$entity_type . '.' . \$bundle . '.default');
foreach (['field_rating' => 10, 'field_review_count' => 11, 'field_orders_this_month' => 12,
          'field_description_body' => 30, 'field_highlight' => 40, 'field_faq' => 50] as \$fn => \$w) {
  if (\$fd && !\$fd->getComponent(\$fn)) {
    \$widget = in_array(\$fn, ['field_description_body', 'field_highlight', 'field_faq'])
      ? 'string_textarea' : 'number';
    if (\$fn === 'field_description_body') \$widget = 'text_textarea';
    \$fd->setComponent(\$fn, ['type' => \$widget, 'weight' => \$w])->save();
  }
}

echo '  Numeric + text fields: done' . PHP_EOL;
"

echo ""
echo "Clearing Drupal cache..."
ddev drush cr

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " All fields created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Go to Commerce > Configuration > Product attributes > Flavor"
echo "     Add the 6 flavor values (Wildflower, Clover, Buckwheat, Cinnamon,"
echo "     Lemon Ginger, Orange Blossom) with swatch colors."
echo ""
echo "  2. Flavor swatch colors from the design:"
echo "     Wildflower:    #f0a929 / #c8851a  |  Notes: Floral · Honeysuckle · Light"
echo "     Clover:        #fde18a / #d9b24a  |  Notes: Mellow · Buttery · Smooth"
echo "     Buckwheat:     #7a4a14 / #4a2c0c  |  Notes: Robust · Malty · Earthy"
echo "     Cinnamon:      #c45a1a / #7a3508  |  Notes: Warm · Spiced · Cozy"
echo "     Lemon Ginger:  #e8b84a / #a8841a  |  Notes: Bright · Zesty · Soothing"
echo "     Orange Blossom:#e89a3a / #a86a14  |  Notes: Citrus · Fragrant · Light"
echo ""
echo "  3. Go to Commerce > Configuration > Product attributes > Pack Size"
echo "     Add label/note/per-stick-price to each pack value."
echo "     Note: design uses 10/30/60/120 sticks — update your values if needed."
echo ""
echo "  4. Edit your Honey Stick product and fill in all the new fields."
echo ""
echo "  5. Run install-pdp.sh to deploy the template, CSS, and JS."
echo ""
