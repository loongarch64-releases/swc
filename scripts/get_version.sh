#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=swc-project
UPSTREAM_REPO=swc

curl -s https://api.github.com/repos/"$UPSTREAM_OWNER"/"$UPSTREAM_REPO"/releases/latest \
     | jq -r ".tag_name"
