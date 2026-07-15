<?php
/**
 * fix-shipments-field-v2.php
 *
 * Adds the 'shipments' entity reference field to Commerce order types
 * by directly using the field storage and config APIs, bypassing
 * commerce_shipping_add_shipments_field() which may not be available.
 *
 * Without this field, ShippingInformation::isVisible() returns false
 * and no shipping address form ever renders.
 *
 * Run:
 *   cp fix-shipments-field-v2.php ~/projects/kartpro/
 *   ddev drush php-script fix-shipments-field-v2.php
 */

if (!\Drupal::moduleHandler()->moduleExists('commerce_shipping')) {
  echo "ERROR: commerce_shipping module is not installed.\n";
  return;
}

$entity_type_manager = \Drupal::entityTypeManager();
$order_types = $entity_type_manager->getStorage('commerce_order_type')->loadMultiple();
$field_manager = \Drupal::service('entity_field.manager');

echo "=== Adding shipments field to order types ===\n\n";

foreach ($order_types as $type_id => $order_type) {
  $field_manager->clearCachedFieldDefinitions();
  $definitions = $field_manager->getFieldDefinitions('commerce_order', $type_id);

  if (isset($definitions['shipments'])) {
    echo "  ✓ '$type_id' already has the shipments field — skipping\n";
    continue;
  }

  echo "  Processing '$type_id'...\n";

  // Step 1: Ensure field storage exists
  $field_storage = \Drupal\field\Entity\FieldStorageConfig::loadByName('commerce_order', 'shipments');
  if (!$field_storage) {
    echo "    Creating field storage...\n";
    try {
      $field_storage = \Drupal\field\Entity\FieldStorageConfig::create([
        'field_name'             => 'shipments',
        'entity_type'            => 'commerce_order',
        'type'                   => 'entity_reference',
        'cardinality'            => -1, // unlimited
        'settings'               => [
          'target_type' => 'commerce_shipment',
        ],
      ]);
      $field_storage->save();
      echo "    ✓ Field storage created\n";
    }
    catch (\Exception $e) {
      if (strpos($e->getMessage(), 'already exists') !== FALSE) {
        echo "    ✓ Field storage already exists (caught)\n";
        $field_storage = \Drupal\field\Entity\FieldStorageConfig::loadByName('commerce_order', 'shipments');
      } else {
        echo "    ERROR creating field storage: " . $e->getMessage() . "\n";
        continue;
      }
    }
  } else {
    echo "    ✓ Field storage already exists\n";
  }

  // Step 2: Create the field instance on this order type
  echo "    Creating field instance on '$type_id'...\n";
  try {
    $field = \Drupal\field\Entity\FieldConfig::create([
      'field_storage' => $field_storage,
      'bundle'        => $type_id,
      'label'         => 'Shipments',
      'required'      => FALSE,
      'settings'      => [
        'handler'          => 'default:commerce_shipment',
        'handler_settings' => [
          'target_bundles' => NULL,
        ],
      ],
    ]);
    $field->save();
    echo "    ✓ Field instance created on '$type_id'\n";
  }
  catch (\Exception $e) {
    if (strpos($e->getMessage(), 'already exists') !== FALSE) {
      echo "    ✓ Field instance already exists (caught)\n";
    } else {
      echo "    ERROR creating field instance: " . $e->getMessage() . "\n";
      continue;
    }
  }
}

// Verify
echo "\n=== Verification ===\n\n";
$field_manager->clearCachedFieldDefinitions();
foreach ($order_types as $type_id => $type) {
  $defs = $field_manager->getFieldDefinitions('commerce_order', $type_id);
  printf("  %-20s shipments = %s\n",
    $type_id,
    isset($defs['shipments']) ? '✓ present' : '✗ STILL MISSING'
  );
}

\Drupal::service('cache.config')->deleteAll();
\Drupal::service('cache.render')->deleteAll();
echo "\n✓ Done. Run 'ddev drush cr' to rebuild caches.\n";
echo "The shipping address form should now appear on the order_information step.\n";
