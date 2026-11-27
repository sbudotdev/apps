# sbudotdev/apps

Free iOS apps and games from [sbu.dev](https://sbu.dev). Each app remakes a single paid utility from the top of the App Store, each game one of the most played free games without its ads: no subscription, no in-app purchases, no account, no ads, no tracking, data only on the device. sbu.dev's third branch, [Software](https://sbu.dev/software), remakes enterprise software as open source; its first project, Sbu Commerce, lives in its own repo.

**On the App Store:** [Sbu Subscriptions](https://apps.apple.com/app/id6780154928), a free alternative to Orbit; [Sbu Scanner](https://apps.apple.com/app/id6772572337), QR codes and barcodes without ads; [Sbu Find](https://apps.apple.com/app/id6823934135), a free alternative to Find Air; [Sbu Moon](https://apps.apple.com/app/id6822656846), moon phases and the next full moon; [Sbu Clean](https://apps.apple.com/app/id6822655310), space back in Photos, one decision at a time; [Sbu Level](https://apps.apple.com/app/id6822656774), a bubble level and clinometer; and [Sbu Noise](https://apps.apple.com/app/id6822655015), noise to sleep to, offline. **For the Mac:** [Sbu Seasons](https://sbu.dev/en/seasons) 2.3.0: snow falls over your Mac's windows and settles on their edges and on the Dock. One new app a week; the rest are below.

<p>
  <a href="https://sbu.dev/en/apps/subscriptions"><img src="https://sbu.dev/og/subscriptions.png" width="49%" alt="Sbu Subscriptions: what your subscriptions cost, and no renewal surprises you"></a>
  <a href="https://sbu.dev/en/apps/scanner"><img src="https://sbu.dev/og/scanner.png" width="49%" alt="Sbu Scanner: reads any code and shows where it goes before you open it"></a>
  <a href="https://sbu.dev/en/apps/moon"><img src="https://sbu.dev/og/moon.png" width="49%" alt="Sbu Moon: moon phase and full moon"></a>
  <a href="https://sbu.dev/en/apps/clean"><img src="https://sbu.dev/og/clean.png" width="49%" alt="Sbu Clean: clear space in your photos"></a>
</p>

Native SwiftUI, one shared design system (`Packages/SbuKit`), Italian and English, iOS 17+. The apps depend only on Apple frameworks: no third-party code, no analytics, no network. MIT licence.

```
Design/            design system snapshot: tokens.json, icons, logos, fonts
Packages/SbuKit/   SwiftUI package: SbuTheme tokens, components, app shell
Apps/Sbu<Name>/    one XcodeGen project per app, with fastlane
Tools/             discover, spec, icons, token sync, new app scaffold
.claude/skills/    Swift agent skills to load before writing Swift (see CLAUDE.md)
```

Design system: https://claude.ai/artifact/A9vJiSmn34wgxe9ePFHLfA

## Setup, once

```sh
brew install xcodegen fastlane
python3 -m venv .venv && .venv/bin/pip install -r Tools/requirements.txt
export ANTHROPIC_API_KEY=...   # only for Tools/spec.py
```

Xcode 26 with an iOS simulator runtime (`xcodebuild -downloadPlatform iOS`).

## Add an app in 5 commands

```sh
python3 Tools/discover.py                           # 1. top-paid IT + US -> research/<app-id>/meta.json + screenshots
.venv/bin/python Tools/spec.py 357421934            # 2. listing + screenshots + 1-3★ reviews -> research/<app-id>/spec.json
Tools/new_app.sh Noise accent-noise noise           # 3. Apps/SbuNoise: project, dev.sbu.noise, SbuKit, icon, fastlane
cd Apps/SbuNoise && fastlane test                   # 4. build the app from spec.json, run the tests
fastlane snapshot && fastlane frames && fastlane beta    # 5. App Store screenshots, panorama (Tools/make_screenshots.py), TestFlight
```

Between 3 and 4 you write the app: start from `MainView.swift`, put strings in `Localizable.xcstrings` (Italian source, English translation), and fill the placeholders in `fastlane/metadata/{it,en-US}`. `new_app.sh` arguments: an English noun, an `accent-*` token not used by a nearby category, and the instrument the icon engraves, in English (needs `GEMINI_API_KEY`).

`new_app.sh` also creates the App Store Connect record when `FASTLANE_USER` (Apple ID) is set: the API key cannot create apps, so `fastlane create_app` logs in with the Apple ID, 2FA once, then the cached session. `fastlane release` uploads build, metadata and framed screenshots without submitting. `beta` and `release` read `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` and `SBU_TEAM_ID`.

## Tools

| | |
|---|---|
| `sync_tokens.py` | Regenerates SbuKit colors (asset catalog, light/dark), metrics and the site's `src/styles/tokens.css` (in `../site`, when cloned) from `Design/tokens.json`. CI fails if they drift. |
| `make_icons.py` | `<name>` → cell icon `Design/icons/sbu-<name>.png` from `cells.json` (ADR-0027); `--appiconset`/`--artwork`/`--inverse`/`--mac-appiconset`/`--watch-appiconset` write the asset catalogs, `all --sheet out.png` the real-size proof. Test: `python3 -m unittest Tools/test_make_icons.py`. |
| `engrave.py` | `<name> --generate` → engraved plate `Design/icons/source/sbu-<name>.png` with Gemini, for the site, the Open Graph previews and the slides. |
| `make_og.py` | Link previews (1200×630) for the site: each app's name closed by its full stop beside its engraving, and the home's title per locale, into `../site/public/og/`. Rerun after a new engraving. |
| `discover.py` | Top-paid charts (Apple marketing RSS) + iTunes Lookup: description, screenshots, price, release notes, genre. |
| `spec.py` | Claude (`claude-opus-5-5`, vision, structured output) → `features[]`, `screens[]`, `flows[]`, `data_model`, `monetization`, `user_pains[]`. |
| `new_app.sh` | Scaffolds `Apps/Sbu<Name>` from `Tools/templates/app` and its site entry `../site/src/content/apps/<name>.md`. |

Specs come only from public App Store data. Nothing here decompiles or extracts assets from other apps.

## Apps

| App | Accent | Remakes | Status |
|---|---|---|---|
| [Sbu Subscriptions](Apps/SbuSubscriptions) | `accent-subscriptions` | Orbit | [App Store](https://apps.apple.com/app/id6780154928) |
| [Sbu Scanner](Apps/SbuScanner) | `accent-scanner` | QR Reader for iPhone | [App Store](https://apps.apple.com/app/id6772572337) |
| [Sbu Find](Apps/SbuFind) | `accent-find` | Find Air | [App Store](https://apps.apple.com/app/id6823934135) |
| [Sbu Moon](Apps/SbuMoon) | `accent-moon` | My Moon Phase Pro | [App Store](https://apps.apple.com/app/id6822656846) |
| [Sbu Clean](Apps/SbuClean) | `accent-clean` | Cleanup | [App Store](https://apps.apple.com/app/id6822655310) |
| [Sbu Level](Apps/SbuLevel) | `accent-level` | Clinometer + bubble level | [App Store](https://apps.apple.com/app/id6822656774) |
| [Sbu Noise](Apps/SbuNoise) | `accent-noise` | White Noise | [App Store](https://apps.apple.com/app/id6822655015) |
| [Sbu Habits](Apps/SbuHabits) | `accent-habits` | Streaks | [App Store](https://apps.apple.com/app/id6821963612) |
| [Sbu Speed](Apps/SbuSpeed) | `accent-speed` | Speedometer 55 Pro. GPS kit. | Rejected |
| [Sbu Chats](Apps/SbuChats) | `accent-chats` | The Cringe: Chat Wrapped | [App Store](https://apps.apple.com/app/id6823369633) |
| [Sbu Fuel](Apps/SbuFuel) | `accent-fuel` | Fuelly: MPG & Service Tracker | Ready for review, week of 30 Nov |
| [Sbu Inventory](Apps/SbuInventory) | `accent-inventory` | Sortly | Ready for review |
| [Sbu Shrink](Apps/SbuShrink) | `accent-shrink` | Compress Videos & Resize Video | In development |
| [Sbu Grid](Apps/SbuGrid) | `accent-grid` | DrawinGrid | In development |
| [Sbu Tidy](Apps/SbuTidy) | `accent-tidy` | Tody | In development |
| [Sbu Libretto](Apps/SbuLibretto) | `accent-libretto` | — | In development |
| [Sbu Squares](Apps/SbuSquares) | `accent-squares` | Block Blast! (game, without its ads) | In development |
| [Sbu Meds](Apps/SbuMeds) | `accent-meds` | Medisafe | In development |
| [Sbu Remote](Apps/SbuRemote) | `accent-remote` | TV Remote - Universal Control | In development |
| [Sbu Prompter](Apps/SbuPrompter) | `accent-prompter` | Moody Teleprompter (Mac + iPhone remote) | 1.0.1, [Download .dmg](https://github.com/sbudotdev/apps/releases/download/prompter-1.0.1/SbuPrompter-1.0.1.dmg) |
| [Sbu Keys](Apps/SbuKeys) | `accent-keys` | Klack (Mac) | In development |
| [Sbu Seasons](Apps/SbuSeasons) | — | — (Mac menu-bar app) | 2.3.0, [Download](https://sbu.dev/en/seasons) |

Live, in review and coming apps, with their pages: [sbu.dev](https://sbu.dev).

## Site

The site lives in [sbudotdev/site](https://github.com/sbudotdev/site), cloned next to this repo (`../site`): it reads `Design/`, `research/` and the fastlane metadata from here. `cd ../site && npm install && npm run dev`. Pages are built from `src/content/apps/*.md` (accent, store id, Originale, FAQ) joined with `Apps/*/fastlane/metadata/{it,en-US}` (name, subtitle, description). An app with a content file but no listing yet gets no page: it shows on the home as "In arrivo" with the `teaser` line from its content file. Set `status: live` and `appStoreId` when an app is on the App Store; its `alternatives/<it|en>/<originale>.md` page is built only then and with `draft: false`. `SBU_DRAFTS=1 npm run build` builds drafts too. Strategy in `docs/marketing/`.
