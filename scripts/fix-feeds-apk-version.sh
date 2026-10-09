#!/bin/sh
# feeds 內某些 package 把 -rN 寫在 PKG_VERSION（opkg 時代可以，apk 會拒收：
#   ERROR: info field 'version' has invalid value / failed to create package）
# 這個腳本把 "-rN" 從 PKG_VERSION 搬到 PKG_RELEASE。每次 ./scripts/feeds update 之後跑一次。
# 用法: sh scripts/fix-feeds-apk-version.sh [feed名...]   預設掃 feeds/*/*/Makefile
set -e
cd "$(dirname "$0")/.."
# 注意 1: feeds update/install 會產生 feeds/<feed>.tmp（掃描用副本，會被重新生成），
#         必須略過，否則只會改到副本、真正的 feeds/<feed>/<pkg>/Makefile 沒被修到。
# 注意 2: 比對/取代都要接受 "PKG_VERSION:=x. y" 這種帶冒號的寫法（舊版 sed 只認
#         "PKG_VERSION ="，等於什麼都沒改，但仍會回報 fixed）。
files=""
for d in feeds/${1:-*}/; do
  case "$d" in *.tmp/) continue;; esac
  [ -d "$d" ] || continue
  files="$files $(ls "$d"${2:-*}/Makefile 2>/dev/null || true)"
done
n=0
for f in $files; do
  ver=$(sed -n 's/^PKG_VERSION *[:?]*= *//p' "$f" | head -1)
  case "$ver" in
    *-r[0-9]*)
      base=${ver%-r*}; rel=${ver##*-r}
      sed -i "s|^PKG_VERSION *[:?]*=.*|PKG_VERSION:=$base|" "$f"
      if grep -q '^PKG_RELEASE' "$f"; then
        sed -i "s|^PKG_RELEASE *[:?]*=.*|PKG_RELEASE:=$rel|" "$f"
      else
        sed -i "/^PKG_VERSION/a PKG_RELEASE:=$rel" "$f"
      fi
      echo "fixed: $f  ($ver -> $base + release $rel)"
      n=$((n+1));;
  esac
done
echo "共修正 $n 個 Makefile"
