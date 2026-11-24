# Sbu Bar arranger spike: findings

Question: can Sbu Bar move another app's menu bar item to a chosen position, reliably, without the pointer visibly moving, and how long does one item take?

Status on 25/11/2026: **listing answered, moving measured, 20/20 (25/11/2026), see "Results" and the run of 25/11/2026 below.** One move ran by mistake on 24/11 and failed (see "Incident").

## What the spike is

`Apps/SbuBar/Spike/` is a SwiftPM executable `BarSpike`, outside the SbuBar XcodeGen target (that target only takes `SbuBar/`). It does not use the `Sections` types. Throwaway: the code is not meant to be kept.

| Command | Does |
|---|---|
| `BarSpike perms` | Accessibility, post-event and Screen Recording state for this process |
| `BarSpike list` | screens (notch areas), status windows from CGWindowList, every app's menu bar items from Accessibility with x, width, owner and label. Read-only |
| `BarSpike move N M` | ⌘-drags item N so it sits immediately right of item M, warps the pointer back, checks the result through Accessibility |
| `BarSpike measure N M [count]` | `count` attempts (default 20), alternating "N right of M" and "N back home"; per attempt OK/FAIL, ms, pointer drift; then success rate, mean, worst |

`move` and `measure` refuse to run without `BAR_SPIKE_MOVE=1`. They take `--post hid|app|agent` (where the synthetic events go) and two timing knobs, `BAR_SPIKE_HOLD_MS` (pause after mouse down, default 30) and `BAR_SPIKE_STEP_MS` (pause between the 6 drag steps, default 15).

## Technique

1. **Read** every running app's `kAXExtrasMenuBarAttribute` (`AXExtrasMenuBar`) and its children (`AXMenuBarItem`/`AXMenuExtra`), with `AXPosition`, `AXSize`, `AXTitle`/`AXDescription`/`AXIdentifier`. Messaging timeout 0.25 s per app so a hung app cannot stall the scan.
2. **Move** with the gesture macOS gives the user: hold ⌘ and drag the item. The spike synthesises it with Quartz Event Services: `leftMouseDown` with `.maskCommand` on the item's centre, 6 `leftMouseDragged` steps along the bar, `leftMouseUp` past the anchor's midpoint (from the left) or on the next item's left half (from the right).
3. **Hide the pointer**: save its location, `CGDisplayHideCursor` before, then `CGWarpMouseCursorPosition` back, `CGAssociateMouseAndMouseCursorPosition(1)`, `CGDisplayShowCursor`.
4. **Verify** through Accessibility: poll for up to 1 s until no item sits between the anchor and the moved item.

Why not something quieter:

- `AXPosition` of a menu bar item is **not settable** (`AXUIElementIsAttributeSettable` returns false on every item on this Mac), and the items expose only `AXPress`. There is no Accessibility action that reorders.
- `NSStatusItem.autosaveName` and the stored positions only apply to the app's own status items. Writing another app's preferences is not public behaviour and needs that app relaunched.
- `--post app|agent` (`CGEvent.postToPid`) is the one route that cannot move the pointer, because the events skip the HID stream. It also skips WindowServer's hit-testing, so it probably does not start a ⌘-drag at all. The spike includes it so the measurement settles it.

Apple documentation:

- Accessibility: [AXUIElement](https://developer.apple.com/documentation/applicationservices/axuielement_h), [kAXExtrasMenuBarAttribute](https://developer.apple.com/documentation/applicationservices/kaxextrasmenubarattribute), [AXIsProcessTrusted](https://developer.apple.com/documentation/applicationservices/1460720-axisprocesstrusted), [AXUIElementSetMessagingTimeout](https://developer.apple.com/documentation/applicationservices/1459914-axuielementsetmessagingtimeout)
- Quartz Event Services: [CGEvent mouse init](https://developer.apple.com/documentation/coregraphics/cgevent/init(mouseeventsource:mousetype:mousecursorposition:mousebutton:)), [CGEvent.post(tap:)](https://developer.apple.com/documentation/coregraphics/cgevent/post(tap:)), [CGEvent.postToPid](https://developer.apple.com/documentation/coregraphics/cgevent/posttopid(_:)), [CGPreflightPostEventAccess](https://developer.apple.com/documentation/coregraphics/cgpreflightposteventaccess()), [CGWarpMouseCursorPosition](https://developer.apple.com/documentation/coregraphics/1456387-cgwarpmousecursorposition), [CGAssociateMouseAndMouseCursorPosition](https://developer.apple.com/documentation/coregraphics/1454486-cgassociatemouseandmousecursorpo), [CGDisplayHideCursor](https://developer.apple.com/documentation/coregraphics/1454426-cgdisplayhidecursor)
- Quartz Window Services: [CGWindowListCopyWindowInfo](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcopywindowinfo), [CGPreflightScreenCaptureAccess](https://developer.apple.com/documentation/coregraphics/cgpreflightscreencaptureaccess())
- Notch: [NSScreen.safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets), [auxiliaryTopLeftArea](https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytopleftarea)
- The user gesture: Mac User Guide, menu bar: hold Command while you drag an icon to rearrange it ([support.apple.com](https://support.apple.com/guide/mac-help/menu-bar-mchlp1446/mac))

**Undocumented API: none.** Everything above is in the public SDK headers.

## What ran on this Mac (macOS 27.2.1, one 1920×1080 display, no notch)

`BarSpike list`, read-only, from iTerm2 (permissions were already granted to iTerm2, so the CLI inherits them):

```
accessibility:       true
post events:         true
screen recording:    true

screens:
  MP273 E14A  frame (0.0, 0.0, 1920.0, 1080.0)  notch false

status windows (CGWindowList, layer 25):
  none: status items have no windows of their own here

items (Accessibility, AXExtrasMenuBar):
   0  x  1532.0  y   3.0  w  24.0  WireGuard — ?
   1  x  1562.0  y   3.0  w  34.0  Google Drive — Google Drive
   2  x  1602.0  y   3.0  w  24.0  SSMenuAgent — Screen Sharing
   3  x  1640.0  y   3.0  w  16.0  SystemUIServer — Siri
   4  x  1671.0  y   4.0  w  22.0  MenuBarAgent — Wi‑Fi, connected, 3 bars
   5  x  1700.0  y   3.0  w  33.0  Siri — Spotlight
   6  x  1740.0  y   4.0  w  26.0  MenuBarAgent — Control Centre
   7  x  1779.0  y   4.0  w 118.0  MenuBarAgent — Clock
```

What this shows:

- **Accessibility lists every item with a usable x and width.** That is enough for `Items` and for verifying a move.
- **On macOS 27 status items have no windows of their own in CGWindowList.** Nothing at the status window layer (25); only "Menubar" (Window Server) and "MenuBarAgent" at layer 24, full width. Any plan that relied on per-item windows (window IDs, per-item captures by window) does not work here. Item images for the Settings lists have to come from a capture of the bar cropped to the AX frame (Screen Recording).
- **System extras live in `MenuBarAgent`** (`com.apple.MenuBarAgent`), each wrapped in an `AXGroup`/`AXHostingView` with the `AXMenuBarItem` one level down, with stable identifiers (`com.apple.menuextra.wifi`, `.controlcenter`, `.clock`). Control Centre's own `AXExtrasMenuBar` returns error -25212 (no value). The spike flattens the groups.
- **Labels are sometimes missing** (WireGuard: no title, description or identifier). `ItemID` cannot rely on the AX label alone; owner bundle id plus order among that owner's items is the fallback.
- **A full scan takes about 3.1 s** on this Mac, because some apps make the AX call wait for the 0.25 s timeout. The real app must scan in the background and re-read only the owners that changed (`NSWorkspace` launch/terminate notifications).

## Incident: one move ran by mistake

On 24/11, while checking argument errors, a build failed and the old binary (without the `--post` parser and without the `BAR_SPIKE_MOVE` guard) ran `move 1 2` with HID events: one ⌘-drag of Google Drive towards Screen Sharing. Result: `FAILED 1242 ms pointer drift 1064 pt restored yes`. The bar order did not change (checked with `list` right after) and the pointer was warped back. This broke the ruling "no events on Matteo's Mac"; the `BAR_SPIKE_MOVE=1` guard was added so it cannot happen again. As a data point: one HID attempt with a 30 ms hold failed, and the pointer did travel (1064 pt from where it was) for about 0.2 s.

## What Matteo runs

From iTerm2 (it already has Accessibility, Screen Recording and event posting; the CLI inherits them). Leave the mouse still while it runs, about 30 s.

```sh
cd ~/dev/sbudotdev/apps/Apps/SbuBar/Spike
swift build
.build/debug/BarSpike list                  # pick N (to move) and M (anchor); N must not be item 0

# 1. one try, watch the pointer and the bar
BAR_SPIKE_MOVE=1 .build/debug/BarSpike move 1 2

# 2. if it failed: slower, the way a hand does it
BAR_SPIKE_MOVE=1 BAR_SPIKE_HOLD_MS=300 BAR_SPIKE_STEP_MS=40 .build/debug/BarSpike move 1 2

# 3. the 20-attempt measurement with the timing that worked
BAR_SPIKE_MOVE=1 BAR_SPIKE_HOLD_MS=300 BAR_SPIKE_STEP_MS=40 .build/debug/BarSpike measure 1 2 20

# 4. the pointer-free routes (expected to fail, settles the question)
BAR_SPIKE_MOVE=1 .build/debug/BarSpike move 1 2 --post agent
BAR_SPIKE_MOVE=1 .build/debug/BarSpike move 1 2 --post app
```

Use a third-party item for N (Google Drive, Screen Sharing), not the Clock. Write down for each run:

- the summary line (`success x/20  mean … ms  worst … ms  max pointer drift … pt`);
- whether you **saw** the pointer jump or flicker (drift in points says how far it travelled, not whether it showed on screen; `CGDisplayHideCursor` from a background CLI may not hide it);
- whether a menu opened (the ⌘-drag should not open it).

Notch and second display (only if at hand; otherwise the MacBook test later):

- **Notch**: on the MacBook, `list` prints where the notch starts and ends. Items under the notch keep an AX frame inside it; a drop on an x inside the notch is not a visible target. Run `measure` with M left of the notch and N right of it.
- **Two displays**: the menu extras show on every display's menu bar; AX reports one frame per item, on the display where the bar is active. Run `measure` once with the pointer parked on each display and note whether the item and the pointer stay on the same display.

If permissions are missing on another Mac or terminal: System Settings › Privacy & Security › **Accessibility** (and **Screen & System Audio Recording** for item images), add the terminal app you run from (here `/Applications/iTerm.app`), quit and reopen it. A binary launched outside a terminal would need `…/Spike/.build/debug/BarSpike` itself added instead.

## Results

| Route | Success /20 | Mean ms | Worst ms | Pointer seen moving | Notes |
|---|---|---|---|---|---|
| hid, 30/15 ms | 0/1 (incident) | 1242 (failed, includes 1 s verify) | – | drift 1064 pt, restored | order unchanged |
| hid, 300/40 ms | pending | | | | |
| agent | pending | | | | |
| app | pending | | | | |

Expected cost per item if `hid` works: hold + 6 steps + 20 ms + verification, about 0.3–0.6 s with the slow knobs; 10 items about 3–6 s. The `Arranger` time limit should start around 1 s per item.

## Risks

- **The pointer will probably be visible.** HID-tap events move the real cursor; warping back restores the position, but hiding it from a background, non-frontmost process may not work. If Matteo sees it, the honest product line is "Sbu Bar moves the pointer for a moment while it arranges", done only on save, with a check afterwards.
- **The user can interfere**: a real mouse move during the drag mixes with the synthetic events. Arrange only on save or on a trigger, never continuously, and verify the result.
- **macOS 27 changed the menu bar host** (`MenuBarAgent`, no per-item windows). The ⌘-drag may have new timing requirements; the incident failure may be exactly that. Future macOS updates can change it again.
- **No public reorder API.** If ⌘-drag through HID events fails at every timing, there is no public alternative: the next options are undocumented (private WindowServer calls) and need an ADR and Matteo's decision.
- Items without any label need a fallback identity (see above).
- Scanning cost (3 s) needs incremental reads in the app.

### Run of 25/11/2026 (macOS 27, one 1920×1080 display, no notch, from the Claude Code terminal with Matteo's go-ahead)

| Run | Result |
|---|---|
| `move 1 2`, default timing | FAILED, 1239 ms, pointer drift 906 pt, restored |
| `move 1 2 --post agent` | FAILED, 1234 ms, drift 0 pt |
| `move 1 2 --post app` | FAILED twice, 1238 / 1231 ms, drift 17 / 4 pt |
| `move 1 2`, `HOLD_MS=300 STEP_MS=40` | OK, 714 ms, drift 769 pt, restored |
| `measure 1 2 20`, `HOLD_MS=300 STEP_MS=40` | **success 20/20, mean 687 ms, worst 752 ms, max drift 773 pt, all restored** |

Conclusions:
- The synthesised ⌘-drag works reliably once the press is held about 300 ms and the drag moves in 40 ms steps. Default timing fails.
- Posting to the agent or app process does not move items: the drag must go through the session event stream, so the pointer does travel (about 770 pt) and is put back at the end.
- Still to check by eye: whether the travel is visible during the ~0.7 s. Not tested: notch, second display.
