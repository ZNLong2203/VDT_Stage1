#!/bin/bash
set -e

superset db upgrade
superset init
printf "admin\nAdmin\nUser\nadmin@superset.com\nadmin\nadmin\n" \
  | superset fab create-admin

exec superset run \
  -p 8088 \
  --with-threads \
  --reload \
  --debugger \
  --host 0.0.0.0
