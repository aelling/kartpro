#!/bin/bash
# cleanup-variations.sh
# ─────────────────────
# Removes non-Wildflower variations from a product and deletes them from the DB.
# The correct model: one product = one flavor, variations = pack sizes only.
#
# Usage (from ~/projects/kartpro):
#   bash cleanup-variations.sh 16        # clean product ID 16
#   bash cleanup-variations.sh           # defaults to first honey_stick product

PRODUCT_ID="${1:-}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — clean up extra variations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PHP_SCRIPT="$(pwd)/_cleanup-variations-tmp.php"

cat > "$PHP_SCRIPT" << PHPEOF
<?php

\$em = \Drupal::entityTypeManager();
\$product_storage = \$em->getStorage('commerce_product');
\$var_storage     = \$em->getStorage('commerce_product_variation');
\$av_storage      = \$em->getStorage('commerce_product_attribute_value');

// ── 1. Load product ───────────────────────────────────────────────────────────
\$product_id = '${PRODUCT_ID}';
if (\$product_id) {
  \$product = \$product_storage->load(\$product_id);
} else {
  \$products = \$product_storage->loadByProperties(['type' => 'honey_stick']);
  if (empty(\$products)) {
    \$products = \$product_storage->loadByProperties(['type' => 'honey_stick_pack']);
  }
  \$product = \$products ? reset(\$products) : NULL;
}

if (!\$product) {
  echo "ERROR: Product not found.\n";
  exit(1);
}
echo "Product: " . \$product->label() . " (ID " . \$product->id() . ")\n";

// ── 2. Determine the keeper flavor: whatever the first variation already has ──
\$variations = \$product->getVariations();
if (empty(\$variations)) {
  echo "No variations found — nothing to do.\n";
  exit(0);
}

// Find the flavor attribute value ID shared by the variations we want to keep.
// We look at every variation and keep whichever flavor appears most (or the first
// one we find if all are the same).
\$flavor_counts = [];
foreach (\$variations as \$v) {
  if (!\$v->hasField('attribute_flavor')) continue;
  \$ref = \$v->get('attribute_flavor');
  if (\$ref->isEmpty()) continue;
  \$fid = (int) \$ref->target_id;
  \$flavor_counts[\$fid] = (\$flavor_counts[\$fid] ?? 0) + 1;
}

if (empty(\$flavor_counts)) {
  echo "No flavor attributes found on variations — nothing to do.\n";
  exit(0);
}

// Keep the most-common flavor (or first if tied)
arsort(\$flavor_counts);
\$keep_flavor_id = array_key_first(\$flavor_counts);
\$keep_flavor_av = \$av_storage->load(\$keep_flavor_id);
echo "Keeping flavor: " . (\$keep_flavor_av ? \$keep_flavor_av->getName() : "ID \$keep_flavor_id") . "\n\n";

// ── 3. Sort into keep / delete ─────────────────────────────────────────────────
\$keep   = [];
\$delete = [];

foreach (\$variations as \$v) {
  \$ref = \$v->hasField('attribute_flavor') ? \$v->get('attribute_flavor') : NULL;
  \$fid = (\$ref && !\$ref->isEmpty()) ? (int) \$ref->target_id : NULL;

  if (\$fid === \$keep_flavor_id || \$fid === NULL) {
    \$keep[] = \$v;
    echo "  ✓ Keep:   " . \$v->getSku() . "\n";
  } else {
    \$delete[] = \$v;
    \$flavor_name = \$av_storage->load(\$fid)?->getName() ?? "flavor \$fid";
    echo "  ✗ Delete: " . \$v->getSku() . " (\$flavor_name)\n";
  }
}

echo "\nKeep: " . count(\$keep) . "  |  Delete: " . count(\$delete) . "\n";

if (empty(\$delete)) {
  echo "Nothing to delete — product already clean.\n";
  exit(0);
}

// ── 4. Detach unwanted variations from product, then delete them ───────────────
foreach (\$delete as \$v) {
  \$product->removeVariation(\$v);
}
\$product->save();
\$var_storage->delete(\$delete);

echo "\nDone. Removed and deleted " . count(\$delete) . " variation(s).\n";
PHPEOF

echo "Running via drush..."
ddev drush php:script _cleanup-variations-tmp.php
rm -f "$PHP_SCRIPT"

echo ""
echo "Clearing cache..."
ddev drush cr

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
