#!/usr/bin/env bash
set -euo pipefail
snag=$(cd "$(dirname "$0")/.." && pwd)/bin/snag
tmp=$(mktemp -d)
export SNAG_DIR=$tmp/snag SNAG_NO_HUD=1 XDG_CONFIG_HOME=$tmp/config
clip=$(pbpaste)
trap 'printf %s "$clip" | pbcopy; rm -rf "$tmp"' EXIT

img=$tmp/seed.png
sips -s format png -Z 512 /System/Applications/Utilities/Screenshot.app/Contents/Resources/AppIcon.icns --out "$img" >/dev/null
fail() { echo "FAIL: $*"; exit 1; }

[[ $($snag done) == "No snags" ]] || fail "done on empty"
[[ $($snag undo) == "No snags" ]] || fail "undo on empty"

czech=$'Tlačítko „Uložit“ přetéká\nA "quoted" word and a second line'
[[ $(SNAG_IMAGE=$img SNAG_NOTE="$czech" $snag add) == "Snag #1 added" ]] || fail add1
! pgrep -qf "snag-hud $SNAG_DIR/" || fail "SNAG_NO_HUD still started a HUD"
[[ $(SNAG_IMAGE=$img SNAG_NOTE="" $snag add) == "Snag #2 added" ]] || fail add2
[[ $(SNAG_IMAGE=$img SNAG_NOTE="to be undone" $snag add) == "Snag #3 added" ]] || fail add3
[[ -f $SNAG_DIR/current/03.png ]] || fail "03.png missing"
[[ $($snag undo) == "Removed #3" ]] || fail undo
[[ ! -e $SNAG_DIR/current/03.png ]] || fail "undo kept 03.png"
[[ $(wc -l < $SNAG_DIR/current/items.jsonl | tr -d ' ') == 2 ]] || fail "undo kept line"
[[ $(jq -r 'select(.n==1).note' $SNAG_DIR/current/items.jsonl) == "$czech" ]] || fail "note did not round-trip"
long=$(printf 'x%.0s' {1..120})
[[ $(SNAG_IMAGE=$img SNAG_NOTE="$long" $snag add) == "Snag #3 added" ]] || fail "add after undo reuses #3"
[[ $($snag done) == "3 snags → "*" (path copied)" ]] || fail done
dest=$(readlink $SNAG_DIR/latest)
[[ -d $dest && ! -e $SNAG_DIR/current ]] || fail "rename or symlink"
[[ $(pbpaste) == "$dest" ]] || fail "path not copied"
md=$dest/issues.md
grep -qx '## 1. Tlačítko „Uložit“ přetéká' $md || fail "heading is not the first note line"
grep -qx '## 2. (no note)' $md || fail "empty note heading"
grep -qx "## 3. $(printf 'x%.0s' {1..79})…" $md || fail "long heading not cut to 80"
grep -qx '!\[01\](01.png)' $md || fail "image link"

SNAG_IMAGE=$img SNAG_NOTE=again $snag add >/dev/null
$snag done >/dev/null
[[ $(readlink $SNAG_DIR/latest) == "$dest-2" ]] || fail "collision suffix"
[[ $($snag ls) == "0 snags" ]] || fail "ls after done"
[[ $($snag latest) == "$dest-2" ]] || fail "latest"

mkdir -p $XDG_CONFIG_HOME/snag
printf 'dir=%s\n' "$tmp/from-config" >$XDG_CONFIG_HOME/snag/config
! env -u SNAG_DIR $snag latest 2>/dev/null || fail "latest with no finished stack"
env -u SNAG_DIR SNAG_IMAGE=$img SNAG_NOTE=cfg $snag add >/dev/null
env -u SNAG_DIR $snag done >/dev/null
[[ $(env -u SNAG_DIR $snag latest) == "$tmp/from-config/"* ]] || fail "config dir= ignored"
[[ $($snag latest) == "$dest-2" ]] || fail "SNAG_DIR does not win over config"
echo ALL OK
