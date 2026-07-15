#!/bin/bash
# Run this from your kartpro project directory:
#   cd ~/projects/kartpro && bash add-product-fields.sh
#
# Creates all 4 custom fields on the Honey Stick product type.

echo "Creating Product Images field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_product_images',
  'entity_type' => 'commerce_product',
  'type' => 'image',
  'cardinality' => 5,
  'settings' => ['uri_scheme' => 'public', 'default_image' => ['uuid' => '', 'alt' => '', 'title' => '', 'width' => NULL, 'height' => NULL]],
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Product Images',
  'required' => TRUE,
  'settings' => ['alt_field' => TRUE, 'alt_field_required' => FALSE, 'title_field' => FALSE, 'file_extensions' => 'png jpg jpeg webp', 'max_filesize' => '5 MB'],
]);
\$field->save();
echo 'Product Images: done';
"

echo "Creating Flavor Description field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_flavor_description',
  'entity_type' => 'commerce_product',
  'type' => 'text_with_summary',
  'cardinality' => 1,
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Flavor Description',
  'required' => TRUE,
]);
\$field->save();
echo 'Flavor Description: done';
"

echo "Creating Ingredients field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_ingredients',
  'entity_type' => 'commerce_product',
  'type' => 'string_long',
  'cardinality' => 1,
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Ingredients',
  'required' => TRUE,
]);
\$field->save();
echo 'Ingredients: done';
"

echo "Creating Nutrition Facts field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_nutrition_facts',
  'entity_type' => 'commerce_product',
  'type' => 'image',
  'cardinality' => 1,
  'settings' => ['uri_scheme' => 'public', 'default_image' => ['uuid' => '', 'alt' => '', 'title' => '', 'width' => NULL, 'height' => NULL]],
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Nutrition Facts',
  'required' => FALSE,
  'settings' => ['alt_field' => FALSE, 'alt_field_required' => FALSE, 'title_field' => FALSE, 'file_extensions' => 'png jpg jpeg', 'max_filesize' => '5 MB'],
]);
\$field->save();
echo 'Nutrition Facts: done';
"

echo ""
echo "All 4 fields created. Clear Drupal cache:"
ddev drush cr
echo "Done! Check Commerce > Configuration > Product types > Honey Stick > Manage fields"
