#!/usr/bin/env bash
# Keep AWDL (AirDrop, AirPlay, Sidecar) down. When it is active, Wi-Fi
# switches channels to serve it, which causes ping spikes. macOS brings the
# interface back up on its own, so check every second.

set -euo pipefail

while true; do
    if ifconfig awdl0 | grep -q "<UP"; then
        (set -x; ifconfig awdl0 down)
    fi

    sleep 1
done
