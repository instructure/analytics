#!/bin/bash
analytics=vendor/plugins/analytics
canvalytics=vendor/plugins/canvalytics

# force correct plugin name
if [ -e $canvalytics ]; then
  if [ -e $analytics ]; then
    set +e
    rm -rf $analytics
    set -e
  fi
  mv $canvalytics $analytics
else
  if [ ! -e $analytics ]; then
    echo "Missing both canvalytics and analytics"
    exit 1
  fi
fi
