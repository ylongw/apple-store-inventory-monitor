#!/bin/zsh
set -eu

env_file="${APW_ENV_FILE:-$HOME/.config/apple-store-inventory-monitor/env}"
if [[ -f "$env_file" ]]; then
  source "$env_file"
fi
if [[ -z "${BARK_API_URL:-}${BARK_API:-}${BARK_URL:-}" ]]; then
  print -u2 '未找到 Bark 环境变量。请设置 BARK_API_URL，或通过 APW_ENV_FILE 指定已有环境文件。'
  exit 1
fi
export BARK_API_URL="${BARK_API_URL:-}" BARK_API="${BARK_API:-}" BARK_URL="${BARK_URL:-}"
export APW_AUTO_START=1 APW_LOG_EVENTS=1
exec "$HOME/Applications/Apple Store Inventory Monitor.app/Contents/MacOS/apple-store-inventory-monitor"
