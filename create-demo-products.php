<?php
/**
 * Demo Honey Stick product generator.
 *
 * Copy this file to your kartpro project root, then run:
 *   cd ~/projects/kartpro
 *   ddev drush php:script create-demo-products.php
 */

use Drupal\commerce_price\Price;
use Drupal\commerce_product\Entity\Product;
use Drupal\commerce_product\Entity\ProductVariation;

// --- Load store ---
$stores = \Drupal::entityTypeManager()->getStorage('commerce_store')->loadMultiple();
$store  = reset($stores);
if (!$store) {
  echo "ERROR: No store found. Create a store in Commerce > Configuration > Stores first.\n";
  exit(1);
}
echo "Using store: " . $store->label() . "\n\n";

// --- Find variation type ---
$vt_storage     = \Drupal::entityTypeManager()->getStorage('commerce_product_variation_type');
$variation_types = $vt_storage->loadMultiple();
$variation_type_id = NULL;
foreach ($variation_types as $vt) {
  echo "Variation type: " . $vt->id() . " (" . $vt->label() . ")\n";
  if (stripos($vt->label(), 'honey') !== FALSE || stripos($vt->id(), 'honey') !== FALSE) {
    $variation_type_id = $vt->id();
  }
}
if (!$variation_type_id) {
  // Fall back to first non-default, then default
  foreach ($variation_types as $vt) {
    if ($vt->id() !== 'default') { $variation_type_id = $vt->id(); break; }
  }
  $variation_type_id = $variation_type_id ?: 'default';
}
echo "Using variation type: $variation_type_id\n\n";

// --- Load Pack Size attribute values ---
$av_storage = \Drupal::entityTypeManager()->getStorage('commerce_product_attribute_value');
$av_ids     = $av_storage->getQuery()
  ->condition('attribute', 'pack_size')
  ->accessCheck(FALSE)
  ->execute();
$av_entities = $av_storage->loadMultiple($av_ids);

$pack_sizes = [];
foreach ($av_entities as $av) {
  $pack_sizes[$av->getName()] = $av;
}
echo "Pack sizes found: " . implode(', ', array_keys($pack_sizes)) . "\n\n";

// --- Prices per pack size ---
$prices = [
  '20 Sticks'    => '8.99',
  '30 Sticks'    => '12.99',
  '50 Sticks'    => '18.99',
  '100 Sticks'   => '32.99',
  'Variety Pack' => '24.99',
];

// --- Flavor definitions ---
$flavors = [
  [
    'title'       => 'Wildflower Honey Sticks',
    'description' => 'Our classic wildflower honey sticks capture the natural sweetness of wildflower meadows. Rich, complex, and perfectly balanced — a crowd favorite for all ages.',
    'ingredients' => 'Pure Wildflower Honey.',
    'sku_prefix'  => 'WILD',
  ],
  [
    'title'       => 'Clover Honey Sticks',
    'description' => 'Light, mild, and classically sweet — our clover honey sticks are the perfect introduction to pure honey. Smooth flavor that kids and adults love equally.',
    'ingredients' => 'Pure Clover Honey.',
    'sku_prefix'  => 'CLOV',
  ],
  [
    'title'       => 'Orange Blossom Honey Sticks',
    'description' => 'Bright, floral, and lightly citrusy — our orange blossom honey sticks bring a sunny sweetness straight from Florida orange groves. A refreshing twist on pure honey.',
    'ingredients' => 'Pure Orange Blossom Honey.',
    'sku_prefix'  => 'OB',
  ],
  [
    'title'       => 'Cinnamon Honey Sticks',
    'description' => 'A warm, spiced blend of pure honey and real cinnamon. Perfect for stirring into tea, oatmeal, or enjoying straight out of the pack.',
    'ingredients' => 'Pure Honey, Natural Cinnamon Flavor.',
    'sku_prefix'  => 'CINN',
  ],
  [
    'title'       => 'Raspberry Honey Sticks',
    'description' => 'Sweet honey meets bright, tangy raspberry in every stick. A fruity favorite that\'s great for lunchboxes, snacks, or a quick natural energy boost.',
    'ingredients' => 'Pure Honey, Natural Raspberry Flavor.',
    'sku_prefix'  => 'RASP',
  ],
];

// --- Pack size SKU suffixes ---
$sku_suffixes = [
  '20 Sticks'    => '20',
  '30 Sticks'    => '30',
  '50 Sticks'    => '50',
  '100 Sticks'   => '100',
  'Variety Pack' => 'VAR',
];

// --- Create products ---
$created = 0;
foreach ($flavors as $flavor) {
  echo "Creating: {$flavor['title']}...\n";

  $variations = [];
  foreach ($pack_sizes as $pack_name => $av) {
    $sku    = $flavor['sku_prefix'] . '-' . ($sku_suffixes[$pack_name] ?? strtoupper(str_replace(' ', '', $pack_name)));
    $amount = $prices[$pack_name] ?? '9.99';

    $variation = ProductVariation::create([
      'type'              => $variation_type_id,
      'sku'               => $sku,
      'price'             => new Price($amount, 'USD'),
      'attribute_pack_size' => $av,
      'status'            => 1,
    ]);
    $variation->save();
    $variations[] = $variation;
    echo "  + $sku @ \$$amount\n";
  }

  $product = Product::create([
    'type'                     => 'honey_stick',
    'title'                    => $flavor['title'],
    'stores'                   => [$store],
    'variations'               => $variations,
    'field_flavor_description' => ['value' => $flavor['description'], 'format' => 'basic_html'],
    'field_ingredients'        => $flavor['ingredients'],
    'status'                   => 1,
  ]);
  $product->save();
  echo "  ✓ Saved (product ID: {$product->id()})\n\n";
  $created++;
}

echo "Done! Created $created products.\n";
echo "View them at: http://kartpro.ddev.site/admin/commerce/products\n";
