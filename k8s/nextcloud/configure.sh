#!/bin/sh
set -eu

php /var/www/html/occ config:system:set loglevel --type=integer --value=2
# Eligible maintenance jobs run from 08:00 to 12:00 UTC.
php /var/www/html/occ config:system:set maintenance_window_start --type=integer --value=8

php /var/www/html/occ config:system:set trusted_domains --type=json \
  --value='["nextcloud.cute.haus", "nextcloud.nextcloud.svc"]'
php /var/www/html/occ config:app:set richdocuments wopi_callback_url \
  --value=http://nextcloud.nextcloud.svc
