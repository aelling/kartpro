#!/bin/bash
# sync-theme.sh — one-shot deploy of theme presentation files into the live theme.
# Copies every workspace CSS / JS / Twig / libraries file OVER the matching file
# that already exists in the active theme, then clears cache.
#
# Safe by design: it only overwrites files that ALREADY exist in the theme (found
# by name), so it never guesses a destination for a brand-new file. New files still
# need their dedicated install-*.sh the first time.
#
# Usage:  cd ~/projects/kartpro && bash sync-theme.sh
#         (or let watch-theme.sh call it automatically)

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
QUIET="${1:-}"        # pass --quiet to suppress the per-file log (used by the watcher)

log() { [ "$QUIET" != "--quiet" ] && echo "$@"; }

# ── Detect theme + its REAL path (docroot = project root; live theme is under
#    themes/, NOT web/themes — resolve via Drupal so we never write to the dead
#    duplicate copy) ───────────────────────────────────────────────────────────
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then echo "ERROR: could not detect theme (is DDEV running?)"; exit 1; fi
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then
  THEME_DIR="$DRUPAL_ROOT/$REL"
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then
  THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"
else
  THEME_DIR=$(find "$DRUPAL_ROOT/web/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
fi
if [ -z "$THEME_DIR" ] || [ ! -d "$THEME_DIR" ]; then echo "ERROR: theme dir not found for '$THEME'"; exit 1; fi

# Files that get RENAMED when deployed (workspace name -> deployed name)
declare -A RENAME=(
  ["homepage.html.twig"]="page--front.html.twig"
  ["hivesticks.libraries.yml"]="${THEME}.libraries.yml"
)

CHANGED=0

# ── Sync loop over all presentation files in the workspace ──────────────────
shopt -s nullglob
for src in "$WORKSPACE"/*.css "$WORKSPACE"/*.js "$WORKSPACE"/*.html.twig "$WORKSPACE"/hivesticks.libraries.yml; do
  base=$(basename "$src")
  target="${RENAME[$base]:-$base}"

  # Find every copy of the target file already present in the theme.
  mapfile -t dests < <(find "$THEME_DIR" -type f -name "$target" 2>/dev/null)
  if [ ${#dests[@]} -eq 0 ]; then
    continue   # not deployed yet — skip (needs its install-*.sh once)
  fi

  for dest in "${dests[@]}"; do
    if ! cmp -s "$src" "$dest"; then
      cp "$src" "$dest"
      log "   ✓ $base → ${dest#$THEME_DIR/}"
      CHANGED=1
    fi
  done
done
shopt -u nullglob

if [ "$CHANGED" -eq 1 ]; then
  ddev drush cr >/dev/null 2>&1
  log "   ↻ cache cleared"
  # Return code 10 = something changed (used by the watcher to print a heartbeat)
  exit 10
else
  log "   (no changes)"
  exit 0
fi
