#!/bin/bash
# Records the scripted app walkthrough (integration_test, TOUR_DEMO) as an MP4.
# Usage: scripts/record_demo.sh <simulator-udid> <output.mp4> [extra flutter args...]
set -u
SIM="$1"; OUT="$2"; shift 2
REC_PID=""
flutter test integration_test/screenshot_tour_test.dart -d "$SIM" --dart-define=TOUR_DEMO=true "$@" 2>&1 |
while IFS= read -r line; do
  echo "$line"
  case "$line" in
    *DEMO_START*)
      xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$OUT" > /dev/null 2>&1 &
      REC_PID=$!
      echo "  -> recording started ($REC_PID)"
      ;;
    *DEMO_END*)
      if [ -n "$REC_PID" ]; then kill -INT "$REC_PID"; wait "$REC_PID" 2>/dev/null; echo "  -> recording saved: $OUT"; fi
      ;;
  esac
done
