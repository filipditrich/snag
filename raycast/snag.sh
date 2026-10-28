#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Snag
# @raycast.mode silent
# @raycast.packageName Snag
# @raycast.icon icon.png
# @raycast.description Screenshot a region and add a note to the current stack

exec "$(dirname "$0")/../bin/snag" add
