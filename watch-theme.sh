#!/bin/bash
# watch-theme.sh — auto-deploy: watches the Cowork workspace and syncs theme
# files into the live site whenever they change. Leave it running in a terminal.
#
#   cd ~/projects/kartpro && bash watch-theme.sh
#   (Ctrl+C to stop)
#
# Why polling? WSL cannot receive inotify file events from /mnt/c (Windows
# drives), so we check for changes every few seconds instead.

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
HERE="$(cd "$(dirname "$0")" && pwd)"
INTERVAL="${1:-3}"     # seconds between checks (default 3)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks auto-sync watcher"
echo " Watching: $WORKSPACE"
echo " Interval: every ${INTERVAL}s   (Ctrl+C to stop)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Do one sync up front so you start in a known-good state.
bash "$HERE/sync-theme.sh"

# Fingerprint = combined hash of all tracked files' size+mtime. Cheap to compute.
fingerprint() {
  find "$WORKSPACE" -maxdepth 1 -type f \
    \( -name "*.css" -o -name "*.js" -o -name "*.html.twig" -o -name "hivesticks.libraries.yml" \) \
    -printf '%p %s %T@\n' 2>/dev/null | sort | md5sum | cut -d' ' -f1
}

last="$(fingerprint)"
while true; do
  sleep "$INTERVAL"
  now="$(fingerprint)"
  if [ "$now" != "$last" ]; then
    ts=$(date '+%H:%M:%S')
    echo "[$ts] change detected — syncing..."
    bash "$HERE/sync-theme.sh"
    last="$now"
  fi
done
