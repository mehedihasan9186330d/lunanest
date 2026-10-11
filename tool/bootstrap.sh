#!/usr/bin/env bash
# Generates android/ and ios/ with `flutter create` (if missing) and applies LunaNest's
# native configuration. Safe to re-run. Requires flutter + python3 on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ] || [ ! -d ios ]; then
  echo "Generating platform folders..."
  BAK="$(mktemp -d)"
  cp -r lib test integration_test assets pubspec.yaml analysis_options.yaml .gitignore "$BAK"/ 2>/dev/null || true
  [ -f README.md ] && cp README.md "$BAK"/ || true
  flutter create --project-name lunanest --org com.lunanest --platforms=android,ios --no-pub .
  # flutter create may overwrite template files: restore ours.
  rm -rf lib test
  cp -r "$BAK/lib" "$BAK/test" .
  cp "$BAK/pubspec.yaml" "$BAK/analysis_options.yaml" "$BAK/.gitignore" .
  [ -f "$BAK/README.md" ] && cp "$BAK/README.md" . || true
  rm -rf integration_test && cp -r "$BAK/integration_test" .
fi

python3 tool/patch_platforms.py
echo "Bootstrap complete."
