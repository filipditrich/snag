#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Snag: Undo Last
# @raycast.mode silent
# @raycast.packageName Snag
# @raycast.icon icon.png
# @raycast.description Remove the last snag from the current stack

exec "$(dirname "$0")/../bin/snag" undo
