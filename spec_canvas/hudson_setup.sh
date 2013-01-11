#!/bin/bash

analytics=vendor/plugins/analytics
canvalytics=vendor/plugins/canvalytics
mra=vendor/plugins/multiple_root_accounts
mra_repo="ssh://hudson@10.86.151.193/home/gerrit/multiple_root_accounts.git"

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

# checkout MRA plugin since we depend on it
if [ ! -e $mra ]; then
    git clone $mra_repo $mra
fi

$mra/spec_canvas/hudson_setup.sh

