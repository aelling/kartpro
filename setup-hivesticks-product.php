<?php
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\commerce_product\Entity\Product;
use Drupal\commerce_product\Entity\ProductVariation;

echo "=== HiveSticks Product Setup ===" . PHP_EOL;

echo PHP_EOL . "Deleting old products..." . PHP_EOL;
$products = \Drupal::entityTypeManager()->getStorage('commerce_product')->loadMultiple();
foreach ($products as $product) {
  foreach ($product->getVariations() as $v) { $v->delete(); }
  $title = $product->label();
  $product->delete();
  echo "  Deleted: $title" . PHP_EOL;
}

echo PHP_EOL . "Adding fields to product type..." . PHP_EOL;
$text_fields = ['field_short_description' => ['label' => 'Short Description', 'type' => 'string'], 'field_bullet_points' => ['label' => 'Bullet Points', 'type' => 'text_long'], 'field_everyday_use' => ['label' => 'Everyday Use', 'type' => 'text_long'], 'field_ingredients' => ['label' => 'Ingredients', 'type' => 'text_long'], 'field_trust' => ['label' => 'Trust Section', 'type' => 'text_long'], 'field_guarantee' => ['label' => 'Guarantee', 'type' => 'text_long']];
foreach ($text_fields as $field_name => $info) {
  if (!FieldStorageConfig::loadByName('commerce_product', $field_name)) {
    FieldStorageConfig::create(['field_name' => $field_name, 'entity_type' => 'commerce_product', 'type' => $info['type'], 'settings' => $info['type'] === 'string' ? ['max_length' => 255] : []])->save();
  }
  if (!FieldConfig::loadByName('commerce_product', 'default', $field_name)) {
    FieldConfig::create(['field_name' => $field_name, 'entity_type' => 'commerce_product', 'bundle' => 'default', 'label' => $info['label']])->save();
    echo "  Created: $field_name" . PHP_EOL;
  } else { echo "  Exists: $field_name" . PHP_EOL; }
}
if (!FieldStorageConfig::loadByName('commerce_product_variation', 'field_pack_description')) {
  FieldStorageConfig::create(['field_name' => 'field_pack_description', 'entity_type' => 'commerce_product_variation', 'type' => 'string', 'settings' => ['max_length' => 255]])->save();
}
if (!FieldConfig::loadByName('commerce_product_variation', 'default', 'field_pack_description')) {
  FieldConfig::create(['field_name' => 'field_pack_description', 'entity_type' => 'commerce_product_variation', 'bundle' => 'default', 'label' => 'Pack Description'])->save();
  echo "  Created: field_pack_description (variation)" . PHP_EOL;
}

echo PHP_EOL . "Creating variations..." . PHP_EOL;
$v25 = ProductVariation::create(['type' => 'default', 'sku' => 'HS-25', 'title' => '25-Pack', 'price' => new \Drupal\commerce_price\Price('11.99', 'USD'), 'field_pack_description' => 'Easy first order. Perfect for trying Hive Sticks, packing in lunchboxes, or keeping a few in your gym bag.', 'status' => TRUE]);
$v25->save();
echo "  25-Pack (\$11.99)" . PHP_EOL;

$v50 = ProductVariation::create(['type' => 'default', 'sku' => 'HS-50', 'title' => '50-Pack', 'price' => new \Drupal\commerce_price\Price('21.99', 'USD'), 'field_pack_description' => 'The everyday pack. Enough for regular use at home, school, practice, work, and travel.', 'status' => TRUE]);
$v50->save();
echo "  50-Pack (\$21.99)" . PHP_EOL;

$v100 = ProductVariation::create(['type' => 'default', 'sku' => 'HS-100', 'title' => '100-Pack', 'price' => new \Drupal\commerce_price\Price('39.99', 'USD'), 'field_pack_description' => 'Best for athletes, families, and teams. Stock up once and keep real honey ready whenever you need it.', 'status' => TRUE]);
$v100->save();
echo "  100-Pack (\$39.99)" . PHP_EOL;

echo PHP_EOL . "Creating product..." . PHP_EOL;
$store = \Drupal::entityTypeManager()->getStorage('commerce_store')->load(1);
$product = Product::create([
  'type' => 'default', 'title' => 'Hive Sticks Classic Honey Sticks',
  'stores' => [$store], 'variations' => [$v25, $v50, $v100], 'status' => TRUE,
  'field_short_description' => 'Raw honey in a tear-and-go stick. Quick energy, no mess, nothing extra.',
  'body' => ['value' => '<p>Hive Sticks make real honey easy to take anywhere.</p><p>No sticky bottles. No artificial energy drinks. No complicated snacks. Just raw honey in a single-serve stick you can keep in your bag, pocket, lunchbox, or car.</p><p>Tear one open before practice, during a long day, on the road, or anytime you want quick natural energy.</p><p>We raise the bees. We harvest the honey. We put it in a stick so you can take it with you.</p><p><strong>Real honey. Nothing added, nothing taken out.</strong></p>', 'format' => 'basic_html'],
  'field_bullet_points' => ['value' => '<ul><li>Raw honey, straight from our hives</li><li>Tear-and-go format for quick energy</li><li>No artificial sweeteners or extra junk</li><li>Great for athletes, kids, travel, coffee, tea, and everyday use</li><li>Mess-free, pocket-sized, and easy to carry</li></ul>', 'format' => 'basic_html'],
  'field_everyday_use' => ['value' => '<h3>Honey that goes where you go.</h3><p>Use Hive Sticks for:</p><ul><li>Pre-practice energy</li><li>Road trips</li><li>Lunchboxes</li><li>Coffee or tea</li><li>Hiking and outdoors</li><li>Quick snacks</li><li>Team bags</li><li>Travel days</li></ul><p>Real honey in a cleaner, easier format.</p>', 'format' => 'basic_html'],
  'field_ingredients' => ['value' => '<p><strong>Raw honey.</strong></p><p>That\'s it. Nothing added. Nothing taken out.</p>', 'format' => 'basic_html'],
  'field_trust' => ['value' => '<p>Iowa Bee is a family-run honey business rooted in a real Iowa farm. We raise our own bees, harvest our own honey, and keep things simple.</p><p>No shortcuts. No fillers. No mystery honey. Just good honey, packed for real life.</p>', 'format' => 'basic_html'],
  'field_guarantee' => ['value' => '<p>We think you\'ll love it. But if you don\'t, let us know and we\'ll make it right.</p>', 'format' => 'basic_html'],
]);
$product->save();
echo "  Created: " . $product->label() . " (ID: " . $product->id() . ")" . PHP_EOL;
echo PHP_EOL . "=== Done! Product URL: /product/" . $product->id() . " ===" . PHP_EOL;
