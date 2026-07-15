#!/bin/bash
set -e
VPS_USER="dh_xsmc68"
VPS_HOST="vps51963.dreamhostps.com"
SITE_PATH="/home/dh_xsmc68/hivesticks.com"
SSH_KEY="$HOME/.ssh/kartpro_deploy"
DRUSH="php $SITE_PATH/vendor/drush/drush/drush.php"
echo "Deploying to VPS..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << ENDSSH
  set -e
  cd $SITE_PATH
  # Preserve settings.php (prod Stripe keys + config_sync_directory)
  mv sites/default/settings.php /tmp/settings.php.bak
  git fetch origin
  git reset --hard origin/main
  cp /tmp/settings.php.bak sites/default/settings.php
  \$DRUSH updatedb -y
  \$DRUSH config:import -y
  \$DRUSH cache:rebuild
  echo "Deploy complete!"
ENDSSH
