#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Snag: Finish
# @raycast.mode silent
# @raycast.packageName Snag
# @raycast.icon icon.png
# @raycast.description Write issues.md and copy the folder path

exec "$(dirname "$0")/../bin/snag" done
