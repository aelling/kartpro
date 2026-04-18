#!/bin/bash
set -e

VPS_USER="dh_xsmc68"
VPS_HOST="vps51963.dreamhostps.com"
SITE_PATH="/home/dh_xsmc68/hivesticks.com"
SSH_KEY="$HOME/.ssh/kartpro_deploy"

echo "Deploying to VPS..."

ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << ENDSSH
  cd $SITE_PATH
  # Preserve settings.php
  mv sites/default/settings.php /tmp/settings.php.bak
  # Sync with GitHub
  git fetch origin
  git reset --hard origin/main
  # Restore settings.php
  cp /tmp/settings.php.bak sites/default/settings.php
  # Run Drupal updates
  php $SITE_PATH/vendor/drush/drush/drush.php cache:rebuild
  php $SITE_PATH/vendor/drush/drush/drush.php updatedb -y
  echo "Deploy complete!"
ENDSSH
