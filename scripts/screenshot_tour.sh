#!/bin/bash
# Runs integration_test/screenshot_tour_test.dart on a simulator and saves a
# screenshot every time the test prints SHOT:<name>.
# Usage: scripts/screenshot_tour.sh <simulator-udid> <out-dir> [extra flutter args...]
set -u
SIM="$1"; OUT="$2"; shift 2
mkdir -p "$OUT"
flutter test integration_test/screenshot_tour_test.dart -d "$SIM" "$@" 2>&1 |
while IFS= read -r line; do
  echo "$line"
  case "$line" in
    *SHOT:*)
      name="${line##*SHOT:}"; name="${name//[^A-Za-z0-9_]/}"
      xcrun simctl io "$SIM" screenshot "$OUT/$name.png" >/dev/null 2>&1 &&
        echo "  -> captured $name"
      ;;
  esac
done
