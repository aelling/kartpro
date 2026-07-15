#!/bin/bash
# find-buynow-block.sh — the header lives in the DATABASE (blocks + menu links),
# not in theme files. This locates the exact block or menu link that renders the
# "Buy Now" button so we can remove it. Run:
#   cd ~/projects/kartpro && bash find-buynow-block.sh
# Paste the whole output back.

echo "══════════════════════════════════════════"
echo " Finding the Buy Now button in the database"
echo "══════════════════════════════════════════"

echo "── 1. Custom block bodies that mention 'Buy Now' or the hs-nav header ──"
ddev drush sqlq "SELECT entity_id, delta FROM block_content__body WHERE body_value LIKE '%Buy Now%' OR body_value LIKE '%hs-nav%';" 2>/dev/null \
  || echo "   (query failed — table name may differ)"
echo ""

echo "── 2. All custom blocks (id | label | type) ──"
ddev drush sqlq "SELECT id, info, type FROM block_content_field_data;" 2>/dev/null
echo ""

echo "── 3. Menu links whose title looks like 'Buy' / 'Shop' (the nav is a menu) ──"
ddev drush sqlq "SELECT id, title, link__uri, menu_name FROM menu_link_content_data WHERE title LIKE '%Buy%' OR title LIKE '%Shop%' OR title LIKE '%Families%';" 2>/dev/null
echo ""

echo "── 4. Every block placed on the site (name | region | plugin) ──"
NAMES=$(ddev drush sqlq "SELECT name FROM config WHERE name LIKE 'block.block.%';" 2>/dev/null)
if [ -z "$NAMES" ]; then
  echo "   (no block.block.* config found)"
else
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    region=$(ddev drush cget "$name" region --format=string 2>/dev/null | tr -d '\r')
    plugin=$(ddev drush cget "$name" plugin --format=string 2>/dev/null | tr -d '\r')
    printf "   %-45s region=%-16s plugin=%s\n" "$name" "$region" "$plugin"
  done <<< "$NAMES"
fi
echo ""

echo "── 5. Full body of any block that contains 'Buy Now' (first 1200 chars) ──"
IDS=$(ddev drush sqlq "SELECT entity_id FROM block_content__body WHERE body_value LIKE '%Buy Now%';" 2>/dev/null)
if [ -n "$IDS" ]; then
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    echo "   ── block_content id=$id ──"
    ddev drush sqlq "SELECT SUBSTRING(body_value,1,1200) FROM block_content__body WHERE entity_id=${id};" 2>/dev/null
    echo ""
  done <<< "$IDS"
else
  echo "   (no custom block body contains 'Buy Now' — it may be a menu link; see section 3)"
fi
echo ""
echo "Done. Paste everything above."
