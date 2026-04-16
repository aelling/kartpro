#!/bin/bash
set -e

VPS_USER="dh_xsmc68"
VPS_HOST="vps51963.dreamhostps.com"
SITE_PATH="/home/dh_xsmc68/hivesticks.com"
SSH_KEY="$HOME/.ssh/kartpro_deploy"

echo "Deploying to VPS..."

ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << ENDSSH
  chmod 755 $SITE_PATH/sites/default
  chmod 644 $SITE_PATH/sites/default/settings.php
  cd $SITE_PATH
  git pull origin main
  php vendor/bin/drush cache:rebuild
  php vendor/bin/drush updatedb -y
  php vendor/bin/drush config:import -y
  echo "Deploy complete!"
ENDSSH
