---
name: egui-visual-debug
description: >
  Visually inspect and debug EGUI (egui/eframe) user interfaces by capturing screenshots
  of running apps and analyzing them for layout, spacing, alignment, and design issues.
  Use this skill whenever the user mentions EGUI layout problems, UI alignment issues,
  visual debugging of Rust GUI apps, or asks you to "look at" / "see" / "check" their
  EGUI interface. Also trigger when the user asks to fix spacing, sizing, styling, or
  visual glitches in an egui or eframe application, or wants help matching a design
  mockup with their EGUI code. Trigger even if the user just says "the UI looks wrong"
  or "can you see what my app looks like" in the context of a Rust/egui project.
---

# EGUI Visual Debug

This skill lets you **see** the rendered state of an EGUI app so you can diagnose and
fix layout, spacing, alignment, and styling issues that are hard to reason about from
code alone.

## Workflow

```
1. Capture  →  2. Analyze  →  3. Fix  →  4. Verify
```

1. **Capture** a screenshot of the EGUI app's window
2. **Analyze** the image — identify layout/design issues
3. **Fix** the code using EGUI layout knowledge (see `references/egui-layout-guide.md`)
4. **Verify** by re-capturing to confirm the fix

Always read `references/egui-layout-guide.md` before suggesting fixes — it contains
the correct EGUI APIs and common pitfalls.

---

## Capturing a Screenshot

The capture script handles the entire flow: build → launch → wait for render →
capture just the app window → kill the process.

### Steps

1. **Build the project:**
   ```bash
   cargo build 2>&1
   ```

2. **Find the binary name** from `Cargo.toml` (look for `[[bin]]` or the package name).

3. **Run the capture script:**
   ```bash
   bash /path/to/skill/scripts/capture_window.sh ./target/debug/my_app /tmp/egui_screenshot.png
   ```
   The script:
   - Launches the binary in the background
   - Waits for the window to render (default 3s, pass a third arg to increase)
   - Finds the app's window ID via CoreGraphics (swift) so it captures **only the app
     window**, not the whole desktop
   - Falls back to full-screen capture if window ID lookup fails
   - Kills the app after capture

4. **View the screenshot** to analyze it. Use your vision capabilities to examine
   the rendered UI.

### If the app needs arguments or env vars

Pass them through by running manually instead of using the script:
```bash
cargo build 2>&1

MY_CONFIG=path/to/config ./target/debug/my_app --some-flag &
APP_PID=$!
sleep 3

# Capture window by PID (uses CoreGraphics via swift — no pip needed)
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
' "$APP_PID" 2>/dev/null)

screencapture -x -o -l "$WINDOW_ID" /tmp/egui_screenshot.png

kill $APP_PID 2>/dev/null
wait $APP_PID 2>/dev/null
```

### If the app needs specific state to capture

Sometimes the default/initial render isn't what you need to debug — e.g., the issue
only appears after opening a dialog or loading data. In these cases, ask the user to:
1. Launch the app themselves and get it into the target state
2. Tell you when it's ready
3. Then you capture with: `screencapture -x -o /tmp/egui_screenshot.png`

### Increasing the delay

Some apps take longer to initialize (loading assets, connecting to services). If the
screenshot comes out blank or shows a partially-rendered frame:
```bash
# Increase delay to 6 seconds
bash /path/to/skill/scripts/capture_window.sh ./target/debug/my_app /tmp/egui_screenshot.png 6
```

---

## Analyzing the Screenshot

When viewing a captured screenshot, systematically check for these categories of issues:

### Layout issues
- **Overlapping widgets** — elements rendered on top of each other
- **Truncated text** — labels or buttons cut off
- **Misaligned columns** — grid/table columns not lining up
- **Uneven spacing** — inconsistent gaps between elements
- **Unwanted scrollbars** — content overflowing its container
- **Empty space** — large unused areas that waste screen real estate

### Sizing issues
- **Widgets too small** to read or interact with
- **Panels not filling** available space (or filling too much)
- **Text scaling** — font sizes that don't match the UI's intent

### Visual/style issues
- **Inconsistent margins/padding** between similar elements
- **Color contrast** problems
- **Missing separators** between logical sections
- **Frame/border** issues

### Responsiveness
- **Fixed sizes** that break at different window dimensions
- **Content reflow** — does the layout adapt when the window is resized?

After identifying issues, read `references/egui-layout-guide.md` for the correct
EGUI patterns to fix them. The guide covers the most common layout APIs and gotchas.

---

## Iterating on Fixes

After making code changes:

1. Re-capture a screenshot using the same method
2. Compare against the previous screenshot — did the fix work?
3. Check for regressions — did fixing one thing break another?
4. If multiple issues exist, fix them incrementally (one at a time) so you can
   verify each change independently

When describing what you see to the user, be specific: reference exact positions
("the label in the top-right panel is clipped by 3-4 characters") rather than vague
descriptions ("some text is cut off").

---

## Quick Reference: Key EGUI Layout Concepts

These are the most frequently needed concepts. For full details and code examples,
read `references/egui-layout-guide.md`.

- **`ui.horizontal()` / `ui.vertical()`** — primary layout direction
- **`ui.with_layout()`** — change layout mid-container
- **`ui.allocate_space()` / `ui.add_space()`** — manual spacing
- **`SidePanel` / `TopBottomPanel` / `CentralPanel`** — top-level layout structure (panels must be added before `CentralPanel`)
- **`ui.available_width()` / `ui.available_height()`** — query remaining space
- **`Strip` / `StripBuilder`** (from `egui_extras`) — precise column/row layouts
- **`Frame`** — add padding, margin, borders around content
- **`ScrollArea`** — scrollable regions, watch for double-scroll bugs
- **`Grid`** — aligned multi-column layouts (not a table — use `egui_extras::Table` for data)
