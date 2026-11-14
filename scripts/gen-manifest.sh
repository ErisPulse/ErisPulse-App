#!/usr/bin/env bash
# 合并 custom/config.json 到 assets/custom/manifest.json。
# 无 custom/config.json 时保持仓库默认清单。
set -euo pipefail

CUSTOM_CONFIG="custom/config.json"
TARGET="assets/custom/manifest.json"

if [ ! -f "$CUSTOM_CONFIG" ]; then
  echo "no custom/config.json — keep default manifest"
  exit 0
fi

command -v jq >/dev/null || { echo "jq is required"; exit 1; }
jq -e . "$CUSTOM_CONFIG" >/dev/null || { echo "invalid JSON: $CUSTOM_CONFIG"; exit 1; }

# 浅合并各 section，preinstalled 整体替换
jq -s '.[0] * .[1]' "$TARGET" "$CUSTOM_CONFIG" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

echo "manifest merged from $CUSTOM_CONFIG:"
jq '{distribution, preinstalled: (.preinstalled | length), defaults, download}' "$TARGET"
