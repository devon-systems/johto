#!/bin/sh
set -eu

php /var/www/html/occ config:system:set trusted_domains --type=json \
  --value='["nextcloud.narwhal-snapper.ts.net", "nextcloud.nextcloud.svc"]'
php /var/www/html/occ config:app:set richdocuments wopi_callback_url \
  --value=http://nextcloud.nextcloud.svc
