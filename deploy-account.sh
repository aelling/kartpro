#!/bin/bash
# deploy-account.sh — deploys the account area (shell + Orders cards + address
# book / profile restyle) to the LIVE theme, and installs the two preprocess
# hooks it needs. Idempotent.
#   cd ~/projects/kartpro && bash deploy-account.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then THEME_DIR="$DRUPAL_ROOT/$REL";
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME";
else echo "ERROR: live theme dir not found"; exit 1; fi
echo "Live theme: $THEME_DIR"
echo ""

mkdir -p "$THEME_DIR/templates/layout" "$THEME_DIR/templates/views" "$THEME_DIR/templates/commerce" "$THEME_DIR/templates/user" "$THEME_DIR/css" "$THEME_DIR/js"

echo "1. Deploying templates / CSS / JS ..."
cp "$WORKSPACE/page--user.html.twig"                      "$THEME_DIR/templates/layout/page--user.html.twig"      && echo "   ✓ page--user.html.twig"
cp "$WORKSPACE/user.html.twig"                            "$THEME_DIR/templates/user/user.html.twig"              && echo "   ✓ user.html.twig (Overview)"
cp "$WORKSPACE/views-view--commerce-user-orders.html.twig" "$THEME_DIR/templates/views/views-view--commerce-user-orders.html.twig" && echo "   ✓ views-view--commerce-user-orders.html.twig"
cp "$WORKSPACE/views-view--commerce-user-subscriptions.html.twig" "$THEME_DIR/templates/views/views-view--commerce-user-subscriptions.html.twig" 2>/dev/null && echo "   ✓ views-view--commerce-user-subscriptions.html.twig"
cp "$WORKSPACE/commerce-order.html.twig"                   "$THEME_DIR/templates/commerce/commerce-order.html.twig" && echo "   ✓ commerce-order.html.twig"
# The order detail renders in the 'user' view mode, whose template suggestion
# (commerce-order--user) is more specific than the base — deploy under that name
# so the theme override wins over Commerce's own commerce-order--user.html.twig.
cp "$WORKSPACE/commerce-order.html.twig"                   "$THEME_DIR/templates/commerce/commerce-order--user.html.twig" && echo "   ✓ commerce-order--user.html.twig"
cp "$WORKSPACE/account.css"                                "$THEME_DIR/css/account.css"                            && echo "   ✓ account.css"
cp "$WORKSPACE/account.js"                                 "$THEME_DIR/js/account.js"                              && echo "   ✓ account.js"
cp "$WORKSPACE/hivesticks.libraries.yml"                   "$THEME_DIR/${THEME}.libraries.yml"                     && echo "   ✓ ${THEME}.libraries.yml"
echo ""

THEME_PHP="$THEME_DIR/${THEME}.theme"
[ -f "$THEME_PHP" ] || printf "<?php\n\n" > "$THEME_PHP"

# Patch the account_active detection (idempotent) so /subscriptions and /rewards
# highlight the right nav item. Safe to run repeatedly.
python3 - "$THEME_PHP" << 'PYEOF'
import sys, re
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
if "account_active'] = 'subscriptions'" not in s and "/address-book') !== FALSE) { $variables['account_active'] = 'addresses'; }" in s:
    s = s.replace(
      "elseif (strpos($path, '/address-book') !== FALSE) { $variables['account_active'] = 'addresses'; }",
      "elseif (strpos($path, '/subscriptions') !== FALSE) { $variables['account_active'] = 'subscriptions'; }\n"
      "    elseif (strpos($path, '/rewards') !== FALSE) { $variables['account_active'] = 'rewards'; }\n"
      "    elseif (strpos($path, '/address-book') !== FALSE) { $variables['account_active'] = 'addresses'; }",
      1)
    open(p, 'w', encoding='utf-8').write(s)
    print("   ✓ patched account_active detection (subscriptions/rewards)")
else:
    print("   ✓ account_active detection already handles subscriptions")
PYEOF

echo "2. Installing preprocess hooks in ${THEME}.theme ..."

if grep -q "hivesticks_preprocess_page__user" "$THEME_PHP"; then
  echo "   ✓ page__user preprocess already present"
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Account-area variables for page--user.html.twig (avatar, name, active section).
 */
function hivesticks_preprocess_page__user(&$variables) {
  $account = \Drupal::currentUser();
  $variables['user_uid'] = $account->id();
  if ($account->isAuthenticated()) {
    $user = \Drupal\user\Entity\User::load($account->id());
    $name = $user ? $user->getDisplayName() : $account->getAccountName();
    $variables['account_name'] = $name;
    $variables['account_email'] = $account->getEmail();
    $parts = preg_split('/[\s@._-]+/', trim((string) $name), -1, PREG_SPLIT_NO_EMPTY);
    $ini = '';
    foreach ($parts as $p) { $ini .= mb_strtoupper(mb_substr($p, 0, 1)); if (mb_strlen($ini) >= 2) break; }
    if ($ini === '') { $ini = mb_strtoupper(mb_substr(trim((string) $name), 0, 2)); }
    $variables['account_initials'] = $ini;
    $path = \Drupal::service('path.current')->getPath();
    if (strpos($path, '/orders') !== FALSE) { $variables['account_active'] = 'orders'; }
    elseif (strpos($path, '/address-book') !== FALSE) { $variables['account_active'] = 'addresses'; }
    elseif (strpos($path, '/edit') !== FALSE) { $variables['account_active'] = 'profile'; }
    else { $variables['account_active'] = 'overview'; }
  }
}
PHP
  echo "   ✓ added hivesticks_preprocess_page__user"
fi

if grep -q "hivesticks_preprocess_views_view__commerce_user_orders" "$THEME_PHP"; then
  echo "   ✓ order-cards preprocess already present"
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Build order-card data for the account Orders view.
 */
function hivesticks_preprocess_views_view__commerce_user_orders(&$variables) {
  if (empty($variables['view']) || empty($variables['view']->result)) {
    return;
  }
  $formatter = \Drupal::service('commerce_price.currency_formatter');
  $date = \Drupal::service('date.formatter');
  $cards = [];
  foreach ($variables['view']->result as $row) {
    $order = isset($row->_entity) ? $row->_entity : NULL;
    if (!$order || $order->getEntityTypeId() !== 'commerce_order') {
      continue;
    }
    $state = $order->getState()->getId();
    $ship = '';
    if ($order->hasField('shipments') && !$order->get('shipments')->isEmpty()) {
      $shipment = $order->get('shipments')->entity;
      if ($shipment) { $ship = $shipment->getState()->getId(); }
    }
    if ($state === 'canceled') { $status = t('Canceled'); $tone = 'muted'; }
    elseif ($ship === 'delivered' || $state === 'completed') { $status = t('Delivered'); $tone = 'done'; }
    elseif ($ship === 'shipped') { $status = t('In transit'); $tone = 'active'; }
    else { $status = t('Processing'); $tone = 'pending'; }

    $items = [];
    $count = 0;
    foreach ($order->getItems() as $item) {
      $q = (int) $item->getQuantity();
      $count += $q;
      if (count($items) < 3) { $items[] = ['title' => $item->getTitle(), 'qty' => $q]; }
    }
    $total = $order->getTotalPrice();
    $total_str = $total ? $formatter->format($total->getNumber(), $total->getCurrencyCode()) : '';
    $ts = $order->getPlacedTime() ?: $order->getCreatedTime();
    $placed = $ts ? $date->format($ts, 'custom', 'M j, Y') : '';
    $uid = $order->getCustomerId();
    $cards[] = [
      'number' => $order->getOrderNumber() ?: $order->id(),
      'status' => $status,
      'tone' => $tone,
      'placed' => $placed,
      'item_count' => $count,
      'total' => $total_str,
      'items' => $items,
      'url' => '/user/' . $uid . '/orders/' . $order->id(),
    ];
  }
  $variables['order_cards'] = $cards;
}
PHP
  echo "   ✓ added hivesticks_preprocess_views_view__commerce_user_orders"
fi

if grep -q "hivesticks_preprocess_commerce_order" "$THEME_PHP"; then
  echo "   ✓ commerce_order preprocess already present"
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Derived status + tracking data for the order detail page.
 */
function hivesticks_preprocess_commerce_order(&$variables) {
  $order = isset($variables['order_entity']) ? $variables['order_entity']
    : (isset($variables['elements']['#commerce_order']) ? $variables['elements']['#commerce_order'] : NULL);
  if (!$order) { return; }
  $state = $order->getState()->getId();
  $ship = '';
  $step = 0;
  $tracking = '';
  $has_shipment = FALSE;
  if ($order->hasField('shipments') && !$order->get('shipments')->isEmpty()) {
    $shipment = $order->get('shipments')->entity;
    if ($shipment) {
      $has_shipment = TRUE;
      $ship = $shipment->getState()->getId();
      if ($shipment->hasField('tracking_code') && !$shipment->get('tracking_code')->isEmpty()) {
        $tracking = $shipment->get('tracking_code')->value;
      }
      if ($ship === 'delivered') { $step = 4; }
      elseif ($ship === 'shipped') { $step = 2; }
      elseif ($ship === 'ready') { $step = 1; }
    }
  }
  if ($state === 'canceled') { $label = t('Canceled'); $tone = 'muted'; }
  elseif ($ship === 'delivered' || $state === 'completed') { $label = t('Delivered'); $tone = 'done'; }
  elseif ($ship === 'shipped') { $label = t('In transit'); $tone = 'active'; }
  else { $label = t('Processing'); $tone = 'pending'; }
  $variables['order_status_label'] = $label;
  $variables['order_status_tone'] = $tone;
  $variables['order_has_shipment'] = $has_shipment;
  $variables['order_track_step'] = $step;
  $variables['order_tracking'] = $tracking;
  $variables['order_canceled'] = ($state === 'canceled');
}
PHP
  echo "   ✓ added hivesticks_preprocess_commerce_order"
fi

if grep -q "hivesticks_preprocess_user" "$THEME_PHP"; then
  echo "   ✓ user (Overview) preprocess already present"
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Overview dashboard data for user.html.twig (/user/{uid}, full view mode).
 */
function hivesticks_preprocess_user(&$variables) {
  if (($variables['elements']['#view_mode'] ?? '') !== 'full') {
    return;
  }
  $account = $variables['user'] ?? ($variables['elements']['#user'] ?? NULL);
  if (!$account) { return; }
  $uid = $account->id();
  $variables['overview_uid'] = $uid;

  $name = $account->getDisplayName();
  $parts = preg_split('/[\s@._-]+/', trim((string) $name), -1, PREG_SPLIT_NO_EMPTY);
  $first = $parts ? $parts[0] : $name;
  $variables['overview_greeting'] = t('Hey @name 🐝', ['@name' => $first]);

  $since = \Drupal::service('date.formatter')->format($account->getCreatedTime(), 'custom', 'F Y');

  $os = \Drupal::entityTypeManager()->getStorage('commerce_order');
  $ids = $os->getQuery()
    ->condition('uid', $uid)
    ->condition('cart', 0)
    ->sort('placed', 'DESC')
    ->accessCheck(FALSE)
    ->execute();
  $orders = $os->loadMultiple($ids);
  $count = count($orders);
  $delivered = 0;
  $latest = NULL;
  $fmt = \Drupal::service('commerce_price.currency_formatter');
  foreach ($orders as $o) {
    $state = $o->getState()->getId();
    $ship = '';
    if ($o->hasField('shipments') && !$o->get('shipments')->isEmpty()) {
      $sh = $o->get('shipments')->entity;
      if ($sh) { $ship = $sh->getState()->getId(); }
    }
    $done = ($ship === 'delivered' || $state === 'completed');
    if ($done) { $delivered++; }
    if ($latest === NULL) {
      if ($state === 'canceled') { $label = t('Canceled'); $tone = 'muted'; }
      elseif ($done) { $label = t('Delivered'); $tone = 'done'; }
      elseif ($ship === 'shipped') { $label = t('In transit'); $tone = 'active'; }
      else { $label = t('Processing'); $tone = 'pending'; }
      $total = $o->getTotalPrice();
      $itemc = 0;
      foreach ($o->getItems() as $it) { $itemc += (int) $it->getQuantity(); }
      $latest = [
        'number' => $o->getOrderNumber() ?: $o->id(),
        'status' => $label,
        'tone' => $tone,
        'total' => $total ? $fmt->format($total->getNumber(), $total->getCurrencyCode()) : '',
        'item_count' => $itemc,
        'url' => '/user/' . $uid . '/orders/' . $o->id(),
      ];
    }
  }
  $variables['overview_subtitle'] = t('Member since @since · @n orders placed', ['@since' => $since, '@n' => $count]);
  $variables['overview_latest'] = $latest;
  $variables['overview_delivered'] = $delivered;

  $ps = \Drupal::entityTypeManager()->getStorage('profile');
  $aids = $ps->getQuery()
    ->condition('uid', $uid)
    ->condition('type', 'customer')
    ->accessCheck(FALSE)
    ->execute();
  $variables['overview_addresses'] = count($aids);
}
PHP
  echo "   ✓ added hivesticks_preprocess_user"
fi

if grep -q "hivesticks_preprocess_views_view__commerce_user_subscriptions" "$THEME_PHP"; then
  echo "   ✓ subscriptions preprocess already present"
else
  cat >> "$THEME_PHP" << 'PHP'

/**
 * Build subscription-card data for the account Subscriptions view.
 */
function hivesticks_preprocess_views_view__commerce_user_subscriptions(&$variables) {
  if (empty($variables['view']) || empty($variables['view']->result)) {
    return;
  }
  $date = \Drupal::service('date.formatter');
  $fmt = \Drupal::service('commerce_price.currency_formatter');
  $cards = [];
  foreach ($variables['view']->result as $row) {
    $sub = isset($row->_entity) ? $row->_entity : NULL;
    if (!$sub || $sub->getEntityTypeId() !== 'commerce_subscription') {
      continue;
    }
    $state = $sub->getState()->getId();
    if ($state === 'canceled') { $status = t('Canceled'); $tone = 'muted'; }
    elseif ($state === 'active') { $status = t('Active'); $tone = 'active'; }
    elseif ($state === 'pending') { $status = t('Pending'); $tone = 'pending'; }
    else { $status = ucfirst($state); $tone = 'done'; }

    $cadence = '';
    if (method_exists($sub, 'getBillingSchedule') && ($schedule = $sub->getBillingSchedule())) {
      $cadence = method_exists($schedule, 'getDisplayLabel') ? ($schedule->getDisplayLabel() ?: $schedule->label()) : $schedule->label();
    }
    $next = '';
    if ($sub->hasField('next_renewal') && !$sub->get('next_renewal')->isEmpty()) {
      $next = $date->format((int) $sub->get('next_renewal')->value, 'custom', 'M j, Y');
    }
    $price = '';
    if (method_exists($sub, 'getUnitPrice') && ($up = $sub->getUnitPrice())) {
      $price = $fmt->format($up->getNumber(), $up->getCurrencyCode());
    }
    $cards[] = [
      'title' => $sub->label(),
      'status' => $status,
      'tone' => $tone,
      'cadence' => $cadence,
      'next' => $next ?: '—',
      'price' => $price,
      'manage_url' => $sub->toUrl()->toString(),
    ];
  }
  $variables['subscription_cards'] = $cards;
}
PHP
  echo "   ✓ added hivesticks_preprocess_views_view__commerce_user_subscriptions"
fi
echo ""

echo "3. Clearing cache ..."
ddev drush cr
echo ""
echo "Done. Visit /user/<uid>/orders (logged in) to see the account area."
