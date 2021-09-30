#!/bin/sh
set -e

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/rocket-pool/smartnode-install/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
CURRENT_VERSION=$(docker inspect rocketpool_node -f '{{ index .Config.Labels "version" }}')

echo "# HELP rocketpool_version_update New Rocket Pool version available"
echo "# TYPE rocketpool_version_update gauge"
if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo "rocketpool_version_update 0"
else
    echo "rocketpool_version_update 1"
fi
