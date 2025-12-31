#!/bin/sh
# Helper script for Sideload to install .deb packages

set -e

DEB_FILE="$1"

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
    echo "ERROR: Invalid package file"
    exit 1
fi

echo "PROGRESS:10"
apt-get update 2>&1 || true

echo "PROGRESS:30"
dpkg -i "$DEB_FILE" 2>&1 || DPKG_FAILED=1

if [ "$DPKG_FAILED" = "1" ]; then
    echo "PROGRESS:60"
    apt-get install -f -y --allow-downgrades 2>&1 || exit 1
fi

echo "PROGRESS:90"

exit 0
