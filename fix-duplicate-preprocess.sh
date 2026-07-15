#!/bin/bash
# fix-duplicate-preprocess.sh
# Removes the old short hivesticks_preprocess_commerce_product() function
# and keeps only the comprehensive one added by install-pdp.sh.
# Run from ~/projects/kartpro:
#   cd ~/projects/kartpro && bash fix-duplicate-preprocess.sh

THEME_FILE=$(find "$HOME/projects/kartpro/themes" -maxdepth 4 -name "hivesticks.theme" 2>/dev/null | head -1)

if [ -z "$THEME_FILE" ]; then
  echo "ERROR: hivesticks.theme not found."
  exit 1
fi

echo "Found: $THEME_FILE"
echo "Removing duplicate preprocess function..."

python3 - "$THEME_FILE" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Remove the OLD short preprocess function (no marker comments around it).
# It starts with the docblock "/** Prepares variables..." OR directly with
# "function hivesticks_preprocess_commerce_product" and ends at its closing }.
# The NEW one is wrapped in /* HIVESTICKS-PREPROCESS-START */ markers, so we
# leave anything inside those markers alone.

# Strategy: find all occurrences of the function declaration.
# The one NOT preceded by the start marker is the old one — remove it.
pattern = re.compile(
    r'(/\*\*[^/]*?\*/\s*)?'            # optional docblock
    r'function hivesticks_preprocess_commerce_product\s*\([^)]*\)\s*\{'  # signature
    r'[^}]*?\}'                         # body (simple, non-nested close)
    r'\s*\n',
    re.DOTALL
)

matches = list(pattern.finditer(content))
print(f"  Found {len(matches)} declaration(s)")

if len(matches) < 2:
    print("  Only one declaration found — nothing to remove. Already fixed?")
    sys.exit(0)

# Remove the FIRST match (the old short one); keep all others
first = matches[0]
content = content[:first.start()] + content[first.end():]

with open(path, 'w') as f:
    f.write(content)

print("  Old function removed.")
PYEOF

echo "Clearing Drupal cache..."
ddev drush cr
echo "Done. Reload the product page."
