# Sbu Bar

Free macOS menu bar app that lets you hide, reorder and bring back the menu bar items of other apps. It lives in the menu bar, no Dock icon. No network, no account, no tracking.

## Why it is not sandboxed

Reading and moving other apps' menu bar items needs Accessibility and Screen Recording, which the sandbox does not allow (ADR-0025). Sbu Bar is distributed as a notarised `.dmg`, not on the Mac App Store.

## Permissions

- **Accessibility**: to read and move the menu bar items.
- **Screen Recording**: to see which items are on screen. Nothing is recorded or stored.

## API di sistema non documentate

Nessuna per ora. Il lettore delle icone (`SystemMenuBarReader`) usa solo le API pubbliche di Accessibilità (`AXExtrasMenuBar`).

## Build

```
cd Apps/SbuBar && xcodegen && xcodebuild test -project SbuBar.xcodeproj -scheme SbuBar -destination 'platform=macOS'
```
