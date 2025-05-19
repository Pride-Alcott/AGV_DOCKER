#!/bin/bash
source /opt/ros/humble/setup.bash
source /AGV/install/setup.bash 2>/dev/null || true
exec "$@"
