#!/bin/bash
# deploy-header-updates.sh
#   1. Adds the Sign in / account link to the header on ALL pages (inner-page
#      templates were missing it) — surgically inserted so your nav is untouched.
#   2. Deploys header.js which now redirects to /cart after add-to-cart.
# Targets the LIVE theme dir (docroot = project root → themes/custom/hivesticks).
#   cd ~/projects/kartpro && bash deploy-header-updates.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

# ── Resolve the REAL theme path ─────────────────────────────────────────────
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then
  THEME_DIR="$DRUPAL_ROOT/$REL"
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then
  THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"
else
  echo "ERROR: could not locate the live theme dir."; exit 1
fi
echo "Live theme dir: $THEME_DIR"
echo ""

# ── 1. header.js (redirect to cart) ─────────────────────────────────────────
echo "1. Deploying header.js (redirect to /cart after add-to-cart)..."
cp "$WORKSPACE/header.js" "$THEME_DIR/js/header.js" && echo "   ✓ js/header.js"
echo ""

# ── 2. Insert Sign in / account link into page templates ────────────────────
echo "2. Adding Sign in link to header templates that lack it..."
python3 - "$THEME_DIR" << 'PY'
import sys, re, glob, os
theme = sys.argv[1]

BLOCK = '''
      {% if logged_in %}
        <a href="/user/{{ user.id }}/orders" class="hs-nav__account-link" aria-label="{{ 'My orders'|t }}">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          <span class="hs-nav__account-text">{{ 'My Orders'|t }}</span>
        </a>
        <a href="{{ path('user.logout') }}" class="hs-nav__signout-link">{{ 'Sign out'|t }}</a>
      {% else %}
        <a href="{{ path('user.login') }}" class="hs-nav__account-link" aria-label="{{ 'Sign in'|t }}">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          <span class="hs-nav__account-text">{{ 'Sign in'|t }}</span>
        </a>
      {% endif %}'''

paths = glob.glob(theme + '/templates/**/page*.html.twig', recursive=True)
changed = 0
for p in paths:
    s = open(p, encoding='utf-8').read()
    if 'hs-nav__actions' not in s:
        continue
    if 'hs-nav__account-link' in s:
        print("   ✓ already has account link:", os.path.relpath(p, theme))
        continue
    # Insert right after the opening <div ... class="hs-nav__actions" ...>
    s2 = re.sub(r'(<div[^>]*class="[^"]*hs-nav__actions[^"]*"[^>]*>)',
                r'\1' + BLOCK, s, count=1)
    if s2 != s:
        open(p, 'w', encoding='utf-8').write(s2)
        print("   ✓ inserted Sign in link:", os.path.relpath(p, theme))
        changed += 1
    else:
        print("   ⚠ could not find actions div in:", os.path.relpath(p, theme))
if changed == 0:
    print("   (no templates modified — check output above)")
PY
echo ""

# ── 3. Make sure the account styles/library load on inner pages ─────────────
# header.css already styles .hs-nav__account-link, and is attached site-wide.
echo "3. Clearing Drupal cache..."
ddev drush cr
echo ""
echo "Done. Hard-refresh. Logged out, every page's header should show 'Sign in';"
echo "adding an item to the cart should send you to /cart."
