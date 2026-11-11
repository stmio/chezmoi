#!/bin/bash
#
# capture_window.sh — Launch an EGUI app, capture its window, and exit.
#
# Usage:
#   bash capture_window.sh <binary_path> <output_path> [delay_seconds]
#
# Arguments:
#   binary_path    — Path to the compiled EGUI binary
#   output_path    — Where to save the PNG screenshot
#   delay_seconds  — How long to wait for the window to render (default: 3)
#
# Examples:
#   bash capture_window.sh ./target/debug/my_app /tmp/screenshot.png
#   bash capture_window.sh ./target/debug/my_app /tmp/screenshot.png 5
#
# What it does:
#   1. Launches the app in the background
#   2. Waits for its window to appear
#   3. Captures ONLY that window (not the whole screen)
#   4. Kills the app
#
# Requirements: macOS (uses screencapture + swift)

set -euo pipefail

BINARY="${1:?Usage: capture_window.sh <binary_path> <output_path> [delay_seconds]}"
OUTPUT="${2:?Usage: capture_window.sh <binary_path> <output_path> [delay_seconds]}"
DELAY="${3:-3}"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY" >&2
    echo "Did you run 'cargo build' first?" >&2
    exit 1
fi

if ! command -v screencapture &>/dev/null; then
    echo "Error: screencapture not found. This script requires macOS." >&2
    exit 1
fi

echo "Launching: $BINARY"
"$BINARY" &
APP_PID=$!

cleanup() {
    if kill -0 "$APP_PID" 2>/dev/null; then
        kill "$APP_PID" 2>/dev/null
        wait "$APP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "Waiting ${DELAY}s for window to render..."
sleep "$DELAY"

if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo "Error: App exited before screenshot could be taken." >&2
    echo "Check for runtime errors by running the binary directly." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Find the app's window ID so we capture just that window, not the desktop.
# Uses CoreGraphics via swift (ships with Xcode CLI tools — no pip needed).
# ---------------------------------------------------------------------------
WINDOW_ID=""

if command -v swift &>/dev/null; then
    WINDOW_ID=$(swift -e '
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
if let list = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] {
    for w in list {
        if let ownerPID = w[kCGWindowOwnerPID as String] as? Int32,
           let layer = w[kCGWindowLayer as String] as? Int,
           let number = w[kCGWindowNumber as String] as? Int,
           ownerPID == pid && layer == 0 {
            print(number)
            break
        }
    }
}
' "$APP_PID" 2>/dev/null || true)
fi

echo "Capturing screenshot..."

if [ -n "$WINDOW_ID" ]; then
    # Capture just the app window by its ID
    # -l <window_id> targets that specific window
    # -o excludes the drop shadow
    screencapture -x -o -l "$WINDOW_ID" "$OUTPUT"
    echo "Captured window ID: $WINDOW_ID"
else
    # Fallback: bring app to front, then capture the full screen.
    # This is less ideal but still works.
    echo "Warning: Could not find window ID, falling back to full screen." >&2
    osascript -e "
        tell application \"System Events\"
            set frontmost of (first process whose unix id is $APP_PID) to true
        end tell
    " 2>/dev/null || true
    sleep 0.5
    screencapture -x -o "$OUTPUT"
fi

if [ -f "$OUTPUT" ]; then
    echo "Screenshot saved to: $OUTPUT"
    if command -v sips &>/dev/null; then
        DIMS=$(sips -g pixelWidth -g pixelHeight "$OUTPUT" 2>/dev/null \
            | grep pixel | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        echo "Dimensions: ${DIMS}"
    fi
else
    echo "Error: Screenshot was not saved." >&2
    exit 1
fi

echo "Done."
