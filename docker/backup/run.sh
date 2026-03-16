#!/bin/bash
set -e

if [ -z "$SCHEDULE" ]; then
  exec /backup.sh
else
  echo "$SCHEDULE /backup.sh >> /proc/1/fd/1 2>&1" | crontab -
  exec crond -f -l 2
fi
