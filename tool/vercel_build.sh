#!/usr/bin/env bash
# Vercel Linux builders do not include Flutter; this script installs the stable
# SDK when VERCEL=1 (or when flutter is missing) then builds the web bundle.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export GIT_TERMINAL_PROMPT=0
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"

ensure_flutter() {
  if [[ -n "${VERCEL:-}" ]] || ! command -v flutter >/dev/null 2>&1; then
    local flutter_dir="${HOME}/flutter_vercel"
    if [[ ! -x "${flutter_dir}/bin/flutter" ]]; then
      rm -rf "${flutter_dir}"
      git clone --depth 1 https://github.com/flutter/flutter.git -b stable "${flutter_dir}"
    fi
    export PATH="${flutter_dir}/bin:${PATH}"
  fi
}

ensure_flutter

flutter config --no-analytics --enable-web
flutter precache --web --no-android --no-ios --no-macos --no-windows
flutter pub get
flutter build web --release --dart-define=USE_REAL_BACKEND=true

echo "Web build complete: ${ROOT}/build/web"
