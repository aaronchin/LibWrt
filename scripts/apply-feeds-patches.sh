#!/bin/sh
# 套用 feeds-patches/<feed>/*.patch 到 feeds/<feed>（git checkout）。
# feeds update 會拉新版覆蓋本地修改，所以每次 ./scripts/feeds update 之後跑一次。
# 可重複執行：已套用的 patch 會略過；套不上（上游改了同一段）會報錯並以非 0 結束。
# 用法: sh scripts/apply-feeds-patches.sh
#
# 注意: feeds update 前若 feed 有本地修改，git pull 可能因衝突失敗。
#       先還原再 update: git -C feeds/<feed> checkout -- .
cd "$(dirname "$0")/.."
rc=0
for p in feeds-patches/*/*.patch; do
  [ -f "$p" ] || continue
  feed=$(basename "$(dirname "$p")")
  dir="feeds/$feed"
  abs="$(pwd)/$p"
  if [ ! -d "$dir/.git" ]; then
    echo "SKIP  $p (no $dir checkout)"
  elif git -C "$dir" apply -R --check "$abs" 2>/dev/null; then
    echo "OK    $p (already applied)"
  elif git -C "$dir" apply "$abs"; then
    echo "APPLY $p"
  else
    echo "FAIL  $p (upstream changed? update the patch)" >&2
    rc=1
  fi
done
exit $rc
