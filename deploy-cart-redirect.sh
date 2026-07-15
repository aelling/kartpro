#!/bin/bash
# deploy-cart-redirect.sh
# The add-to-cart form is a normal (non-AJAX) POST, so the redirect must be done
# server-side: a hook_form_alter that appends a submit handler redirecting to the
# cart page. Installs into the LIVE theme's hivesticks.theme.
#   cd ~/projects/kartpro && bash deploy-cart-redirect.sh

DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then
  THEME_DIR="$DRUPAL_ROOT/$REL"
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then
  THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"
else
  echo "ERROR: could not locate live theme dir."; exit 1
fi
THEME_PHP="$THEME_DIR/${THEME}.theme"
echo "Live theme: $THEME_DIR"
[ -f "$THEME_PHP" ] || printf "<?php\n\n" > "$THEME_PHP"

if grep -q "${THEME}_redirect_to_cart" "$THEME_PHP"; then
  echo "✓ Cart-redirect form_alter already present — nothing to do."
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Implements hook_form_alter().
 *
 * The add-to-cart form is a normal POST (not AJAX), so we redirect to the cart
 * page by appending a submit handler.
 */
function THEME_form_alter(&$form, \Drupal\Core\Form\FormStateInterface $form_state, $form_id) {
  if (strpos($form_id, 'commerce_order_item_add_to_cart_form') !== FALSE) {
    if (isset($form['actions']['submit'])) {
      $form['actions']['submit']['#submit'][] = 'THEME_redirect_to_cart';
    }
    else {
      $form['#submit'][] = 'THEME_redirect_to_cart';
    }
  }
}

/**
 * Submit handler: send the shopper to the cart page after adding an item.
 */
function THEME_redirect_to_cart(array &$form, \Drupal\Core\Form\FormStateInterface $form_state) {
  $form_state->setRedirect('commerce_cart.page');
}
PHP
  sed -i "s/THEME_form_alter/${THEME}_form_alter/g; s/THEME_redirect_to_cart/${THEME}_redirect_to_cart/g" "$THEME_PHP"
  echo "✓ Added ${THEME}_form_alter + ${THEME}_redirect_to_cart to ${THEME}.theme"
fi

echo "Clearing cache..."
ddev drush cr
echo "Done. Click Add to Cart on a product — it should now land on /cart."
