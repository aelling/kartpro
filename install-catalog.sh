#!/bin/bash
# install-catalog.sh
# ──────────────────
# Sets up the HiveSticks /shop catalog page end-to-end:
#
#   1. Creates "Product category" taxonomy vocabulary (product_category)
#   2. Creates category terms: Single flavors / Bundles & gifts / Subscriptions
#   3. Adds field_category (taxonomy ref) to Commerce products if absent
#   4. Copies catalog CSS + Twig templates to the theme
#   5. Updates hivesticks.libraries.yml
#   6. Creates the "catalog" Drupal View at /shop via Drush PHP
#   7. Adds preprocess hooks to hivesticks.theme
#   8. Clears Drupal cache
#
# Usage (from your kartpro project root, with DDEV running):
#   bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/install-catalog.sh

set -e

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks Catalog — install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Find theme ──────────────────────────────────────────────────────
echo "1. Detecting active theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "   ERROR: Could not detect theme. Is DDEV running? (ddev start)"; exit 1
fi
THEME_DIR=$(find "$DRUPAL_ROOT/web/themes" -maxdepth 4 -type d -name "$THEME" 2>/dev/null | head -1)
[ -z "$THEME_DIR" ] && THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 4 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  echo "   ERROR: Theme directory not found for '$THEME'"; exit 1
fi
echo "   Theme: $THEME → $THEME_DIR"
echo ""

# ── 2. Create directories ──────────────────────────────────────────────
mkdir -p "$THEME_DIR/css"
mkdir -p "$THEME_DIR/templates/views"
mkdir -p "$THEME_DIR/templates/commerce"
echo "2. Directories ready."
echo ""

# ── 3. Deploy CSS ──────────────────────────────────────────────────────
echo "3. Installing catalog.css..."
cp "$WORKSPACE/catalog.css" "$THEME_DIR/css/catalog.css"
echo "   ✓ catalog.css → $THEME_DIR/css/"
echo ""

# ── 4. Deploy Twig templates ───────────────────────────────────────────
echo "4. Installing Twig templates..."
cp "$WORKSPACE/views-view--catalog.html.twig"                       "$THEME_DIR/templates/views/"
cp "$WORKSPACE/views-view-unformatted--catalog.html.twig"           "$THEME_DIR/templates/views/"
cp "$WORKSPACE/views-exposed-form--catalog.html.twig"               "$THEME_DIR/templates/views/"
# commerce-product--honey-stick--teaser.html.twig is the most-specific suggestion
# (bundle + view_mode beats bundle-only), so it wins over commerce-product--honey-stick.html.twig
cp "$WORKSPACE/commerce-product--honey-stick--teaser.html.twig"     "$THEME_DIR/templates/commerce/"
echo "   ✓ views-view--catalog.html.twig"
echo "   ✓ views-view-unformatted--catalog.html.twig"
echo "   ✓ views-exposed-form--catalog.html.twig"
echo "   ✓ commerce-product--honey-stick--teaser.html.twig"
echo ""

# ── 5. Deploy libraries YAML ───────────────────────────────────────────
echo "5. Installing hivesticks.libraries.yml..."
cp "$WORKSPACE/hivesticks.libraries.yml" "$THEME_DIR/${THEME}.libraries.yml"
echo "   ✓ ${THEME}.libraries.yml"
echo ""

# ── 6. Taxonomy: product_category vocab + terms ────────────────────────
echo "6. Setting up product_category taxonomy..."
ddev drush php:eval "
// Create vocabulary if it doesn't exist
\$storage = \Drupal::entityTypeManager()->getStorage('taxonomy_vocabulary');
if (!\$storage->load('product_category')) {
  \$vocab = \$storage->create([
    'vid'         => 'product_category',
    'name'        => 'Product category',
    'description' => 'Catalog filter categories for HiveSticks products.',
  ]);
  \$vocab->save();
  echo 'Created vocabulary: product_category' . PHP_EOL;
} else {
  echo 'Vocabulary product_category already exists.' . PHP_EOL;
}

// Create terms if absent
\$term_storage = \Drupal::entityTypeManager()->getStorage('taxonomy_term');
\$terms = [
  ['name' => 'Single flavors',   'weight' => 0],
  ['name' => 'Bundles & gifts',  'weight' => 1],
  ['name' => 'Subscriptions',    'weight' => 2],
];
foreach (\$terms as \$t) {
  \$existing = \$term_storage->loadByProperties(['vid' => 'product_category', 'name' => \$t['name']]);
  if (empty(\$existing)) {
    \$term = \$term_storage->create(['vid' => 'product_category', 'name' => \$t['name'], 'weight' => \$t['weight']]);
    \$term->save();
    echo 'Created term: ' . \$t['name'] . PHP_EOL;
  } else {
    echo 'Term already exists: ' . \$t['name'] . PHP_EOL;
  }
}
"
echo ""

# ── 7. Add field_category to commerce_product ──────────────────────────
echo "7. Adding field_category to commerce_product entity..."
ddev drush php:eval "
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;

// Field storage (shared across bundles)
if (!FieldStorageConfig::loadByName('commerce_product', 'field_category')) {
  FieldStorageConfig::create([
    'field_name'   => 'field_category',
    'entity_type'  => 'commerce_product',
    'type'         => 'entity_reference',
    'cardinality'  => 1,
    'settings'     => ['target_type' => 'taxonomy_term'],
  ])->save();
  echo 'Created field_category storage.' . PHP_EOL;
} else {
  echo 'field_category storage already exists.' . PHP_EOL;
}

// Field instance on honey_stick bundle (adjust bundle name if different)
\$bundles = array_keys(\Drupal::service('entity_type.bundle.info')->getBundleInfo('commerce_product'));
foreach (\$bundles as \$bundle) {
  if (!FieldConfig::loadByName('commerce_product', \$bundle, 'field_category')) {
    FieldConfig::create([
      'field_name'   => 'field_category',
      'entity_type'  => 'commerce_product',
      'bundle'       => \$bundle,
      'label'        => 'Product category',
      'required'     => FALSE,
      'settings'     => [
        'handler'          => 'default:taxonomy_term',
        'handler_settings' => ['target_bundles' => ['product_category' => 'product_category']],
      ],
    ])->save();
    echo 'Added field_category to bundle: ' . \$bundle . PHP_EOL;
  } else {
    echo 'field_category already on bundle: ' . \$bundle . PHP_EOL;
  }
}
"
echo ""

# ── 8. Create the catalog View via config YAML import ─────────────────
echo "8. Creating catalog View at /shop (config YAML import)..."
if ddev drush php:eval "echo \Drupal::entityTypeManager()->getStorage('view')->load('catalog') ? 'exists' : 'missing';" 2>/dev/null | grep -q 'exists'; then
  echo "   View catalog already exists — skipping import."
else
  # Use a subdir inside the project root — ddev mounts it at /var/www/html/tmp-config
  mkdir -p "$DRUPAL_ROOT/tmp-config"
  cp "$WORKSPACE/views.view.catalog.yml" "$DRUPAL_ROOT/tmp-config/views.view.catalog.yml"
  if ddev drush config:import --partial --source=/var/www/html/tmp-config -y 2>&1; then
    echo "   ✓ View catalog created at /shop"
  else
    echo "   WARNING: Config import failed. Create the View manually:"
    echo "   Admin → Structure → Views → Add view"
    echo "   Name: Catalog | Show: Commerce Product | Page at /shop"
    echo "   Row: Rendered entity (Teaser view mode)"
  fi
  rm -rf "$DRUPAL_ROOT/tmp-config"
fi
echo ""

# ── 9. Set URL alias /shop → /shop (or whatever the View path produces) ─
echo "9. Adding /shop path alias (if path_alias module is active)..."
ddev drush php:eval "
if (\Drupal::moduleHandler()->moduleExists('path_alias')) {
  \$alias_storage = \Drupal::entityTypeManager()->getStorage('path_alias');
  \$existing = \$alias_storage->loadByProperties(['alias' => '/shop']);
  if (empty(\$existing)) {
    // The View's path IS /shop already, so no alias needed.
    // This step creates a redirect from /products → /shop if desired.
    echo 'View path is /shop — no additional alias needed.' . PHP_EOL;
  } else {
    echo '/shop path already exists.' . PHP_EOL;
  }
}
"
echo ""

# ── 10. Inject preprocess hooks into hivesticks.theme ──────────────────
echo "10. Checking hivesticks.theme for catalog preprocess hooks..."
THEME_FILE="$THEME_DIR/${THEME}.theme"
if [ ! -f "$THEME_FILE" ]; then
  # Create the file with opening PHP tag
  echo "<?php" > "$THEME_FILE"
  echo "" >> "$THEME_FILE"
  echo "/**" >> "$THEME_FILE"
  echo " * @file" >> "$THEME_FILE"
  echo " * HiveSticks theme functions." >> "$THEME_FILE"
  echo " */" >> "$THEME_FILE"
  echo "" >> "$THEME_FILE"
  echo "   Created $THEME_FILE"
fi

# Check if our hooks are already there
if grep -q "hivesticks_preprocess_commerce_product__honey_stick__teaser" "$THEME_FILE" 2>/dev/null; then
  echo "   Preprocess hooks already present in $THEME_FILE"
else
  cat >> "$THEME_FILE" << 'PHPEOF'

/**
 * Preprocess for Commerce product teaser cards on the /shop catalog.
 * Template: commerce-product--honey-stick--teaser.html.twig
 *
 * Adds:
 *   $variables['price_from']       — formatted cheapest variation price, e.g. "$8"
 *   $variables['is_subscription']  — TRUE for subscription-category products
 *   $variables['single_variation'] — TRUE when product has exactly 1 variation
 *   $variables['swatch']           — hex color from field_swatch_color
 */
function hivesticks_preprocess_commerce_product__honey_stick__teaser(&$variables) {
  /** @var \Drupal\commerce_product\Entity\ProductInterface $product */
  $product = $variables['product_entity'] ?? NULL;
  if (!$product) return;

  // ── Swatch color ──────────────────────────────────────────────────
  $variables['swatch'] = $product->hasField('field_swatch_color') && !$product->get('field_swatch_color')->isEmpty()
    ? $product->get('field_swatch_color')->value
    : '#f0a929';

  // ── "From" price: cheapest variation ─────────────────────────────
  $min_price = NULL;
  try {
    $variations = $product->getVariations();
    $variables['single_variation'] = count($variations) === 1;
    foreach ($variations as $variation) {
      $price = $variation->getPrice();
      if (!$price) continue;
      if ($min_price === NULL || $price->compareTo($min_price) < 0) {
        $min_price = $price;
      }
    }
    if ($min_price) {
      $currency_formatter = \Drupal::service('commerce_price.currency_formatter');
      $formatted = $currency_formatter->format(
        $min_price->getNumber(),
        $min_price->getCurrencyCode()
      );
      $variables['price_from'] = preg_replace('/\.00$/', '', $formatted);
    }
  }
  catch (\Exception $e) {
    \Drupal::logger('hivesticks')->warning('Price error on teaser: @msg', ['@msg' => $e->getMessage()]);
  }

  // ── Subscription flag ─────────────────────────────────────────────
  $variables['is_subscription'] = FALSE;
  if ($product->hasField('field_category') && !$product->get('field_category')->isEmpty()) {
    $term = $product->get('field_category')->entity;
    if ($term && stripos($term->label(), 'subscri') !== FALSE) {
      $variables['is_subscription'] = TRUE;
    }
  }
}

/**
 * Builds category pill data and sort options for the catalog view template.
 * Pills use plain GET-param links — no exposed Views form needed.
 */
function hivesticks_preprocess_views_view__catalog(&$variables) {
  $request     = \Drupal::request();
  $current_tid = (int) $request->query->get('field_category_target_id', 0);
  $query_all   = $request->query->all();

  // ── Category pills ────────────────────────────────────────────────
  $terms = \Drupal::entityTypeManager()
    ->getStorage('taxonomy_term')
    ->loadByProperties(['vid' => 'product_category']);
  uasort($terms, fn($a, $b) => $a->getWeight() <=> $b->getWeight());

  $pills = [];

  // "All" pill
  $all_query = array_merge($query_all, ['field_category_target_id' => '']);
  $pills[] = [
    'label'  => t('All products'),
    'url'    => \Drupal\Core\Url::fromRoute('<current>', [], ['query' => $all_query])->toString(),
    'active' => $current_tid === 0,
    'count'  => NULL,
  ];

  foreach ($terms as $term) {
    $tid   = (int) $term->id();
    $count = \Drupal::entityQuery('commerce_product')
      ->condition('status', 1)
      ->condition('field_category', $tid)
      ->accessCheck(TRUE)
      ->count()
      ->execute();

    $cat_query = array_merge($query_all, ['field_category_target_id' => $tid]);
    $pills[] = [
      'label'  => $term->label(),
      'url'    => \Drupal\Core\Url::fromRoute('<current>', [], ['query' => $cat_query])->toString(),
      'active' => $current_tid === $tid,
      'count'  => $count,
    ];
  }
  $variables['catalog_pills']      = $pills;
  $variables['catalog_active_tid'] = $current_tid ?: '';

  // ── Sort options ──────────────────────────────────────────────────
  $active_sort = $request->query->get('sort_by', 'featured');
  $variables['catalog_sort_active']  = $active_sort;
  $variables['catalog_sort_options'] = [
    ['value' => 'featured',   'label' => t('Featured')],
    ['value' => 'price-asc',  'label' => t('Price: low to high')],
    ['value' => 'price-desc', 'label' => t('Price: high to low')],
    ['value' => 'rating',     'label' => t('Top rated')],
  ];
}

/**
 * Filters catalog View by field_category_target_id GET param,
 * and applies sort_by GET param ordering.
 */
function hivesticks_views_query_alter(\Drupal\views\ViewExecutable $view, \Drupal\views\Plugin\views\query\QueryPluginBase $query) {
  if ($view->id() !== 'catalog') return;

  $request = \Drupal::request();

  // ── Category filter ───────────────────────────────────────────────
  $tid = (int) $request->query->get('field_category_target_id', 0);
  if ($tid > 0) {
    /** @var \Drupal\views\Plugin\views\query\Sql $query */
    $query->addTable('commerce_product__field_category');
    $query->addWhere(0, 'commerce_product__field_category.field_category_target_id', $tid, '=');
  }

  // ── Sort order ────────────────────────────────────────────────────
  $sort_by = $request->query->get('sort_by', 'featured');
  // Clear existing sorts, then apply chosen one
  $query->orderby = [];
  switch ($sort_by) {
    case 'price-asc':
      $query->addTable('commerce_product_variation_field_data');
      $query->addOrderBy('commerce_product_variation_field_data', 'price__number', 'ASC');
      break;
    case 'price-desc':
      $query->addTable('commerce_product_variation_field_data');
      $query->addOrderBy('commerce_product_variation_field_data', 'price__number', 'DESC');
      break;
    case 'rating':
      // Sort by field_rating descending if it exists
      try {
        $query->addTable('commerce_product__field_rating');
        $query->addOrderBy('commerce_product__field_rating', 'field_rating_value', 'DESC');
      }
      catch (\Exception $e) {
        $query->addOrderBy('commerce_product_field_data', 'product_id', 'ASC');
      }
      break;
    default:
      // Featured: use product_id ASC (natural entry order)
      $query->addOrderBy('commerce_product_field_data', 'product_id', 'ASC');
      break;
  }
}
PHPEOF
  echo "   ✓ Appended preprocess + query_alter hooks to $THEME_FILE"
fi
echo ""

# ── 11. Clear cache ────────────────────────────────────────────────────
echo "11. Clearing Drupal cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Catalog install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Visit the catalog page:"
echo "     https://kartpro.ddev.site/shop"
echo ""
echo "  2. Assign categories to your products:"
echo "     Admin → Commerce → Products → [edit each product]"
echo "     Set the 'Product category' field:"
echo "       Single flavors   — Wildflower, Clover, Buckwheat, Cinnamon, Lemon Ginger, Orange Blossom"
echo "       Bundles & gifts  — Variety Pack, Gift Box, Family Stockpile"
echo "       Subscriptions    — Monthly Honey Box"
echo ""
echo "  3. If the category filter pills aren't showing, make sure"
echo "     the View's exposed filter field is named 'field_category_target_id'."
echo "     Admin → Structure → Views → Catalog → edit."
echo ""
echo "  4. The /shop nav link is in page.html.twig and homepage.html.twig."
echo "     Both currently link to #hs-shop (homepage anchor). Update them to:"
echo "       href=\"{{ path('<front>') }}#hs-shop\""
echo "     or add a Shop link to https://kartpro.ddev.site/shop once catalog is live."
echo ""
