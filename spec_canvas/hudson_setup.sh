#!/bin/bash

set -o errexit

# force correct plugin name
mv vendor/plugins/canvalytics vendor/plugins/analytics

set +e
rm -rf "vendor/plugins/multiple_root_accounts"
set -e

# checkout MRA plugin since we depend on it
git clone "ssh://hudson@gerrit.instructure.com:29418/multiple_root_accounts.git" "vendor/plugins/multiple_root_accounts"
