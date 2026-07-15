#!/bin/bash
# seed-pdp-content.sh
# ───────────────────
# Populates Flavor attribute values (with swatch colors), Pack Size attribute
# value labels/notes, and seeds sample content on your first Honey Stick product.
#
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash seed-pdp-content.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks PDP — seed content"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Write the PHP script into the Drupal root so DDEV's container can find it
# (/tmp/ is on the WSL host; DDEV only mounts ~/projects/kartpro/)
PHP_SCRIPT="$(pwd)/_seed-pdp-tmp.php"

cat > "$PHP_SCRIPT" << 'PHPEOF'
<?php

use Drupal\commerce_product\Entity\ProductAttribute;
use Drupal\commerce_product\Entity\ProductAttributeValue;

$entity_type_manager = \Drupal::entityTypeManager();
$av_storage = $entity_type_manager->getStorage('commerce_product_attribute_value');
$product_storage = $entity_type_manager->getStorage('commerce_product');

// ═══════════════════════════════════════════════════════════════════
// A. FLAVOR ATTRIBUTE VALUES
// ═══════════════════════════════════════════════════════════════════
echo "\nA. Seeding Flavor attribute values...\n";

$flavors = [
  [
    'name'     => 'Wildflower',
    'weight'   => 0,
    'swatch'   => '#f0a929',
    'deep'     => '#c8851a',
    'notes'    => 'Floral · Honeysuckle · Light',
    'tagline'  => 'Pure wildflower',
  ],
  [
    'name'     => 'Clover',
    'weight'   => 1,
    'swatch'   => '#fde18a',
    'deep'     => '#d9b24a',
    'notes'    => 'Mellow · Buttery · Smooth',
    'tagline'  => 'Classic clover',
  ],
  [
    'name'     => 'Buckwheat',
    'weight'   => 2,
    'swatch'   => '#7a4a14',
    'deep'     => '#4a2c0c',
    'notes'    => 'Robust · Malty · Earthy',
    'tagline'  => 'Bold & dark',
  ],
  [
    'name'     => 'Cinnamon',
    'weight'   => 3,
    'swatch'   => '#c45a1a',
    'deep'     => '#7a3508',
    'notes'    => 'Warm · Spiced · Cozy',
    'tagline'  => 'Spiced honey',
  ],
  [
    'name'     => 'Lemon Ginger',
    'weight'   => 4,
    'swatch'   => '#e8b84a',
    'deep'     => '#a8841a',
    'notes'    => 'Bright · Zesty · Soothing',
    'tagline'  => 'Citrus kick',
  ],
  [
    'name'     => 'Orange Blossom',
    'weight'   => 5,
    'swatch'   => '#e89a3a',
    'deep'     => '#a86a14',
    'notes'    => 'Citrus · Fragrant · Light',
    'tagline'  => 'Floral citrus',
  ],
];

foreach ($flavors as $flavor) {
  $existing = $av_storage->loadByProperties([
    'attribute' => 'flavor',
    'name'      => $flavor['name'],
  ]);

  if (!empty($existing)) {
    $av = reset($existing);
    echo "  Updating {$flavor['name']}...\n";
  } else {
    $av = $av_storage->create([
      'attribute' => 'flavor',
      'name'      => $flavor['name'],
      'weight'    => $flavor['weight'],
    ]);
    echo "  Creating {$flavor['name']}...\n";
  }

  if ($av->hasField('field_swatch_color'))   $av->set('field_swatch_color',   $flavor['swatch']);
  if ($av->hasField('field_swatch_deep'))    $av->set('field_swatch_deep',    $flavor['deep']);
  if ($av->hasField('field_flavor_notes'))   $av->set('field_flavor_notes',   $flavor['notes']);
  if ($av->hasField('field_flavor_tagline')) $av->set('field_flavor_tagline', $flavor['tagline']);
  $av->save();
  echo "    ✓ {$flavor['name']} saved\n";
}

echo "  Flavor attribute: done\n";

// ═══════════════════════════════════════════════════════════════════
// B. PACK SIZE ATTRIBUTE VALUES
// ═══════════════════════════════════════════════════════════════════
echo "\nB. Seeding Pack Size attribute values...\n";

// Map existing pack size names → label data
// Adjust the keys if your pack names differ
$pack_data = [
  '20 Sticks' => [
    'label'      => 'Starter',
    'note'       => 'Try every flavor',
    'per_stick'  => '0.90',
    'is_popular' => FALSE,
    'save_label' => '',
  ],
  '30 Sticks' => [
    'label'      => 'Popular',
    'note'       => 'Best for daily use',
    'per_stick'  => '0.83',
    'is_popular' => TRUE,
    'save_label' => 'Save 8%',
  ],
  '50 Sticks' => [
    'label'      => 'Value',
    'note'       => 'Stock up & save',
    'per_stick'  => '0.78',
    'is_popular' => FALSE,
    'save_label' => 'Save 13%',
  ],
  '100 Sticks' => [
    'label'      => 'Family',
    'note'       => 'Share with everyone',
    'per_stick'  => '0.70',
    'is_popular' => FALSE,
    'save_label' => 'Save 22%',
  ],
  'Variety Pack' => [
    'label'      => 'Variety',
    'note'       => 'One of each flavor',
    'per_stick'  => '0.90',
    'is_popular' => FALSE,
    'save_label' => '',
  ],
];

$all_packs = $av_storage->loadByProperties(['attribute' => 'pack_size']);
if (empty($all_packs)) {
  echo "  ⚠ No Pack Size attribute values found — skipping.\n";
  echo "    Go to Commerce > Configuration > Product attributes > Pack Size\n";
  echo "    and add your pack size values first, then re-run this script.\n";
} else {
  foreach ($all_packs as $av) {
    $name = $av->getName();
    if (!isset($pack_data[$name])) {
      echo "  Skipping unknown pack size: {$name}\n";
      continue;
    }
    $data = $pack_data[$name];
    echo "  Updating {$name}...\n";
    if ($av->hasField('field_pack_label'))      $av->set('field_pack_label',      $data['label']);
    if ($av->hasField('field_pack_note'))       $av->set('field_pack_note',       $data['note']);
    if ($av->hasField('field_pack_per_stick'))  $av->set('field_pack_per_stick',  $data['per_stick']);
    if ($av->hasField('field_pack_is_popular')) $av->set('field_pack_is_popular', $data['is_popular']);
    if ($av->hasField('field_pack_save_label')) $av->set('field_pack_save_label', $data['save_label']);
    $av->save();
    echo "    ✓ {$name} updated\n";
  }
}
echo "  Pack Size attribute: done\n";

// ═══════════════════════════════════════════════════════════════════
// C. HONEY STICK PRODUCT — seed sample content
// ═══════════════════════════════════════════════════════════════════
echo "\nC. Seeding Honey Stick product fields...\n";

$products = $product_storage->loadByProperties(['type' => 'honey_stick']);

if (empty($products)) {
  echo "  ⚠ No Honey Stick product found — skipping product seed.\n";
  echo "    Create a product first: Commerce > Products > Add product > Honey Stick\n";
  echo "    Then re-run this script to populate the detail fields.\n";
} else {
  // Use the first honey_stick product found
  $product = reset($products);
  echo "  Found product: " . $product->label() . " (ID " . $product->id() . ")\n";

  // Only overwrite fields that are currently empty so we don't stomp real data
  $set_if_empty = function($product, $field, $value) {
    if (!$product->hasField($field)) return;
    $current = $product->get($field)->value;
    if (!empty($current)) {
      echo "    · {$field} already has content — skipping\n";
      return;
    }
    $product->set($field, $value);
    echo "    ✓ {$field} set\n";
  };

  $set_if_empty($product, 'field_subtitle',          'Raw · Unfiltered · Single-Origin Iowa Honey');
  $set_if_empty($product, 'field_rating',            4.8);
  $set_if_empty($product, 'field_review_count',      142);
  $set_if_empty($product, 'field_orders_this_month', 890);
  $set_if_empty($product, 'field_quality_badge',     'RAW · UNFILTERED');
  $set_if_empty($product, 'field_batch_label',       "NEW BATCH · MAY '26");
  $set_if_empty($product, 'field_net_weight',        '7 g per stick');
  $set_if_empty($product, 'field_origin',            'Iowa, USA');
  $set_if_empty($product, 'field_harvest',           'Spring–Summer 2026');
  $set_if_empty($product, 'field_shelf_life',        '2 years (unopened)');
  $set_if_empty($product, 'field_storage',           'Store in a cool, dry place');
  $set_if_empty($product, 'field_allergens',         'None');
  $set_if_empty($product, 'field_certifications',    'All-natural · No additives · Non-GMO');

  if ($product->hasField('field_description_body') && empty($product->get('field_description_body')->value)) {
    $product->set('field_description_body',
      'Pure, raw honey straight from Iowa hives — filtered only enough to remove wax, ' .
      'never heated above 95°F. Each stick holds exactly 7 grams: the same amount as a ' .
      'standard honey packet, in a form that travels anywhere without the mess.'
    );
    echo "    ✓ field_description_body set\n";
  } else {
    echo "    · field_description_body already has content — skipping\n";
  }

  // Highlights — only set if the field is completely empty
  if ($product->hasField('field_highlight') && $product->get('field_highlight')->isEmpty()) {
    $product->set('field_highlight', [
      ['value' => '01|||Raw & Unfiltered|||Never heated above 95°F. Every enzyme, antioxidant, and pollen grain stays intact.'],
      ['value' => '02|||Single-Origin Iowa|||Sourced from our own hives on an Iowa wildflower farm — traceable to the hive.'],
      ['value' => '03|||No Mess, No Spoon|||Bite, squeeze, enjoy. The stick format travels in your pocket, bag, or gym kit.'],
      ['value' => '04|||Compostable Wrapper|||The cellulose wrapper goes in your compost bin. Zero plastic guilt.'],
    ]);
    echo "    ✓ field_highlight set (4 items)\n";
  } else {
    echo "    · field_highlight already has content — skipping\n";
  }

  // FAQ — only set if completely empty
  if ($product->hasField('field_faq') && $product->get('field_faq')->isEmpty()) {
    $product->set('field_faq', [
      ['value' => 'Is the honey really raw?|||Yes. Raw means it was never heated above 95°F — the temperature inside a healthy hive. Heat destroys enzymes and darkens the color. Ours stays light and fragrant.'],
      ['value' => 'How do I use a honey stick?|||Bite or snip one end, then squeeze directly into tea, onto food, or straight into your mouth. No spoon, no drips.'],
      ['value' => 'Are these organic?|||Our honey is from Iowa hives managed without pesticides. We\'re working toward USDA Organic certification — watch this space.'],
      ['value' => 'Do you ship internationally?|||Not yet — US only for now. We\'re working on it. Sign up for our email list and we\'ll let you know when your country goes live.'],
      ['value' => 'What\'s your return policy?|||30-day no-questions returns. If you\'re not happy, email hello@hivesticks.com and we\'ll refund you in full — keep the sticks.'],
    ]);
    echo "    ✓ field_faq set (5 items)\n";
  } else {
    echo "    · field_faq already has content — skipping\n";
  }

  $product->save();
  echo "  Product saved ✓\n";
}

echo "\n";
PHPEOF

echo "Running seed script via drush..."
echo ""
ddev drush php:script _seed-pdp-tmp.php
rm "$PHP_SCRIPT"

echo ""
echo "Clearing Drupal cache..."
ddev drush cr
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Seed complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to check:"
echo ""
echo "  1. Visit your Honey Stick product page — the PDP should now"
echo "     show real data: subtitle, rating, highlights, FAQ."
echo ""
echo "  2. The flavor swatch picker and pack picker are JS-driven."
echo "     Open the browser console — if drupalSettings.hivesticks"
echo "     is populated, the pickers will build automatically."
echo ""
echo "  3. To edit any content: Commerce > Products > [your product] > Edit"
echo "     Field values set by this script can be overwritten freely."
echo ""
echo "  4. To add product variations (one per flavor):"
echo "     Product edit > Variations tab > Add variation"
echo "     Each variation needs a Flavor attribute value + price."
echo ""
