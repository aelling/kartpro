#!/bin/bash
# Run this from your kartpro project directory:
#   cd ~/projects/kartpro && bash add-badge-fields.sh
#
# Adds 2 new fields to the Honey Stick product type:
#   field_quality_badge  — e.g. "RAW · UNFILTERED"
#   field_batch_label    — e.g. "NEW BATCH · MAY '26"

echo "Creating Quality Badge field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_quality_badge',
  'entity_type' => 'commerce_product',
  'type' => 'string',
  'cardinality' => 1,
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Quality Badge',
  'required' => FALSE,
  'description' => 'Short attribute badge shown above the title, e.g. \"RAW · UNFILTERED\"',
]);
\$field->save();

// Add to default form display
\$form_display = \Drupal\Core\Entity\Entity\EntityFormDisplay::load('commerce_product.honey_stick.default');
if (\$form_display) {
  \$form_display->setComponent('field_quality_badge', [
    'type' => 'string_textfield',
    'weight' => 0,
    'settings' => ['size' => 60, 'placeholder' => 'e.g. RAW · UNFILTERED'],
  ])->save();
}

// Add to default view display
\$view_display = \Drupal\Core\Entity\Entity\EntityViewDisplay::load('commerce_product.honey_stick.default');
if (\$view_display) {
  \$view_display->setComponent('field_quality_badge', [
    'type' => 'string',
    'label' => 'hidden',
    'weight' => 0,
  ])->save();
}

echo 'Quality Badge: done';
"

echo "Creating Batch Label field..."
ddev drush php:eval "
\$storage = \Drupal\field\Entity\FieldStorageConfig::create([
  'field_name' => 'field_batch_label',
  'entity_type' => 'commerce_product',
  'type' => 'string',
  'cardinality' => 1,
]);
\$storage->save();
\$field = \Drupal\field\Entity\FieldConfig::create([
  'field_storage' => \$storage,
  'bundle' => 'honey_stick',
  'label' => 'Batch Label',
  'required' => FALSE,
  'description' => 'Freshness badge shown above the title, e.g. \"NEW BATCH · MAY \'26\"',
]);
\$field->save();

// Add to default form display
\$form_display = \Drupal\Core\Entity\Entity\EntityFormDisplay::load('commerce_product.honey_stick.default');
if (\$form_display) {
  \$form_display->setComponent('field_batch_label', [
    'type' => 'string_textfield',
    'weight' => 1,
    'settings' => ['size' => 60, 'placeholder' => 'e.g. NEW BATCH · MAY \'26'],
  ])->save();
}

// Add to default view display
\$view_display = \Drupal\Core\Entity\Entity\EntityViewDisplay::load('commerce_product.honey_stick.default');
if (\$view_display) {
  \$view_display->setComponent('field_batch_label', [
    'type' => 'string',
    'label' => 'hidden',
    'weight' => 1,
  ])->save();
}

echo 'Batch Label: done';
"

echo ""
echo "Clearing Drupal cache..."
ddev drush cr

echo ""
echo "Done! Both fields are now on the Honey Stick product type."
echo "Fill them in at: Commerce > Products > [your product] > Edit"
echo ""
echo "Twig variables to use in your template:"
echo "  Quality badge:  {{ product_entity.field_quality_badge.value }}"
echo "  Batch label:    {{ product_entity.field_batch_label.value }}"
