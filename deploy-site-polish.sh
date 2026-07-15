#!/bin/bash
# deploy-site-polish.sh — nav-link fixes + sitewide avatar chip + site name +
# front-title report + pre-launch test-data cleanup.
#   cd ~/projects/kartpro && bash deploy-site-polish.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then THEME_DIR="$DRUPAL_ROOT/$REL";
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"; fi
[ -z "$THEME_DIR" ] && { echo "ERROR: live theme dir not found"; exit 1; }
echo "Live theme: $THEME_DIR"

# ── 1. Deploy templates (nav links + avatar chip) ───────────────────────────
echo "1. Deploying templates + CSS..."
cp "$WORKSPACE/page.html.twig"       "$THEME_DIR/templates/layout/page.html.twig"
cp "$WORKSPACE/page.html.twig"       "$THEME_DIR/templates/page.html.twig"
cp "$WORKSPACE/homepage.html.twig"   "$THEME_DIR/templates/layout/page--front.html.twig"
cp "$WORKSPACE/homepage.html.twig"   "$THEME_DIR/templates/page--front.html.twig"
cp "$WORKSPACE/page--user.html.twig" "$THEME_DIR/templates/layout/page--user.html.twig"
cp "$WORKSPACE/account.css"          "$THEME_DIR/css/account.css"
echo "   ✓ page/homepage/page--user + account.css"

# ── 2. Patch preprocess_page(+__front) to expose avatar initials/name ───────
echo "2. Patching avatar variables into ${THEME}.theme..."
python3 - "$THEME_DIR/${THEME}.theme" << 'PYEOF'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
marker = "$variables['user_uid'] = $current_user->id();"
block = r'''
  /* hs-avatar */
  if ($current_user->isAuthenticated()) {
    $__a = \Drupal\user\Entity\User::load($current_user->id());
    $__n = $__a ? $__a->getDisplayName() : $current_user->getAccountName();
    $variables['account_name'] = $__n;
    $__pp = preg_split('/[\s@._-]+/', trim((string) $__n), -1, PREG_SPLIT_NO_EMPTY);
    $__i = '';
    foreach ($__pp as $__x) { $__i .= mb_strtoupper(mb_substr($__x, 0, 1)); if (mb_strlen($__i) >= 2) break; }
    $variables['account_initials'] = $__i ?: mb_strtoupper(mb_substr(trim((string) $__n), 0, 2));
  }'''
if '/* hs-avatar */' in s:
    print("   ✓ avatar vars already present")
elif marker in s:
    s = s.replace(marker, marker + block)
    open(p, 'w', encoding='utf-8').write(s)
    print("   ✓ patched avatar vars into preprocess_page / __front")
else:
    print("   ⚠ user_uid marker not found — avatar chip falls back to Twig display name")
PYEOF

# ── 3. Site name + front-title report + test-data cleanup ───────────────────
echo "3. Site name, front-title report, and cleanup..."
cat > "$DRUPAL_ROOT/hs_polish.php" <<'PHP'
<?php
$c = \Drupal::configFactory()->getEditable('system.site');
$c->set('name', 'HiveSticks')->save();
print 'Site name -> HiveSticks' . PHP_EOL;

$front = \Drupal::config('system.site')->get('page.front');
print 'Front page route: ' . $front . PHP_EOL;
if (preg_match('#/node/(\d+)#', $front, $m)) {
  $n = \Drupal::entityTypeManager()->getStorage('node')->load($m[1]);
  if ($n) {
    $old = $n->getTitle();
    if ($old !== 'Raw Single-Origin Honey Sticks') {
      $n->setTitle('Raw Single-Origin Honey Sticks');
      $n->save();
      print 'Front node title: "' . $old . '" -> "Raw Single-Origin Honey Sticks"' . PHP_EOL;
    }
    else { print 'Front node title already set.' . PHP_EOL; }
  }
}
if (\Drupal::moduleHandler()->moduleExists('metatag')) {
  foreach (['metatag.metatag_defaults.front', 'metatag.metatag_defaults.global'] as $cfg) {
    $tags = \Drupal::config($cfg)->get('tags');
    if (!empty($tags['title'])) { print $cfg . ' title tag: "' . $tags['title'] . '"' . PHP_EOL; }
  }
}

$sub_ids = \Drupal::entityQuery('commerce_subscription')->accessCheck(FALSE)->condition('title', 'TEST — %', 'LIKE')->execute();
if ($sub_ids) {
  $st = \Drupal::entityTypeManager()->getStorage('commerce_subscription');
  $st->delete($st->loadMultiple($sub_ids));
  print 'Deleted ' . count($sub_ids) . ' test subscription(s)' . PHP_EOL;
}
else { print 'No test subscriptions found' . PHP_EOL; }

\Drupal::service('user.data')->delete('hs_rewards', 1, 'points');
print 'Cleared seeded reward points for uid 1' . PHP_EOL;
print 'Done.' . PHP_EOL;
PHP
ddev drush php:script hs_polish.php
rm -f "$DRUPAL_ROOT/hs_polish.php"

echo ""
echo "4. Clearing cache..."
ddev drush cr
echo ""
echo "Done. Nav links now point to homepage anchors, header shows the avatar chip"
echo "sitewide, site name is HiveSticks, and test data is cleaned up."
echo "The front-title source is printed above — paste it if it still shows the demo name."
