#!/bin/bash
# deploy-nav.sh — copies updated nav files to kartpro and clears cache
WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
THEME="$HOME/projects/kartpro/themes/custom/hivesticks"

# Remove stale root-level copy that shadows layout/ version
rm -f "$THEME/templates/page.html.twig"
cp "$WORKSPACE/page.html.twig" "$THEME/templates/layout/page.html.twig" && echo "✓ page.html.twig" || echo "✗ page.html.twig FAILED"
cp "$WORKSPACE/header.css"     "$THEME/css/header.css"                  && echo "✓ header.css"      || echo "✗ header.css FAILED"
cp "$WORKSPACE/header.js"      "$THEME/js/header.js"                    && echo "✓ header.js"       || echo "✗ header.js FAILED"
cp "$WORKSPACE/homepage.css"   "$THEME/css/homepage.css"                && echo "✓ homepage.css"    || echo "✗ homepage.css FAILED"

cd "$HOME/projects/kartpro" && ddev drush cr && echo "✓ cache cleared" || echo "✗ cache clear FAILED"
