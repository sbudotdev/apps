# Sbu Bar 1.0, piano 1: progetto, spike del riordino, fondamenta

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** creare `Apps/SbuBar`, provare che si può riordinare un'icona di un'altra app nella barra dei menu senza muovere il puntatore, e costruire le fondamenta testate (identità delle icone, modello delle sezioni, archivio JSON, lettura delle icone).

**Architecture:** app Mac solo barra dei menu (`MenuBarExtra`), SwiftUI con SbuKit. La logica pura (`Sections`, `Store`) è in tipi `nonisolated` testati con Swift Testing; le parti di sistema stanno dietro protocolli (`MenuBarReading`, `MenuBarMoving`) con versioni finte nei test. I piani successivi (Reveal, Settings, Strip, Search, Appearance, Profiles, Triggers, gruppi, Displays, .dmg) si scrivono dopo l'esito dello spike.

**Tech Stack:** Swift 6, SwiftUI, AppKit, ApplicationServices (Accessibilità), CoreGraphics, Swift Testing, XcodeGen, macOS 15.

**Spec:** `docs/superpowers/specs/2026-11-24-sbu-bar-design.md` (design), `research/apps/bartender.md` (comportamento), `docs/adr/0025-sbu-bar-fuori-dalla-sandbox.md` (vincoli).

## Global Constraints

- **Clean room.** Leggi solo: questo piano, i tre file della riga «Spec», `CLAUDE.md`, i file di questo repo e la documentazione pubblica di Apple. Nessun materiale fuori da queste fonti: niente binari, analisi o file di altre app. Niente codice di Ice (GPL-3.0), Hidden Bar o altri progetti: scrivi da zero.
- macOS 15.0 minimo; Swift 6.0; `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`; `SWIFT_STRICT_CONCURRENCY: complete`; tipi valore puri `nonisolated`.
- Bundle id `dev.sbu.bar`; nome visibile «Sbu Bar»; cartella `Apps/SbuBar`.
- Fuori dalla sandbox (`com.apple.security.app-sandbox: false`), `ENABLE_HARDENED_RUNTIME: YES`, `LSUIElement: YES`.
- Dipendenze: solo SbuKit e framework Apple. Nessuna rete (l'unica eccezione, MapKit nel trigger Posizione, arriva in un piano successivo).
- Colori, misure, durate, font solo da `SbuTheme`/`SbuAccent`; mai letterali. Accento `accent-bar` e `accent-on-ink-bar` aggiunti a `Design/tokens.json`, poi `python3 Tools/sync_tokens.py`.
- Stringhe in `Localizable.xcstrings`, italiano sorgente più inglese, seconda persona singolare, niente emoji né punti esclamativi.
- Un tipo per file, cartelle per funzione. Test con Swift Testing (`struct`, `#expect`, parametrizzati).
- Test: `cd Apps/SbuBar && xcodegen && xcodebuild test -project SbuBar.xcodeproj -scheme SbuBar -destination 'platform=macOS'`.
- Commit dopo ogni task, sul branch locale `app/bar`. Mai push né merge.

---

### Task 1: progetto SbuBar e accento

**Files:**
- Create: `Apps/SbuBar/project.yml`
- Create: `Apps/SbuBar/SbuBar/App/SbuBarApp.swift`
- Create: `Apps/SbuBar/SbuBar/SbuBar.entitlements`
- Create: `Apps/SbuBar/SbuBar/Localizable.xcstrings`
- Create: `Apps/SbuBar/SbuBarTests/SmokeTests.swift`
- Create: `Apps/SbuBar/README.md`
- Modify: `Design/tokens.json` (dopo le voci `accent-keys` e `accent-on-ink-keys`)

**Interfaces:**
- Produces: target `SbuBar` e `SbuBarTests`, `SbuAccent.bar` generato da `sync_tokens.py`.

- [ ] **Step 1: aggiungi i token.** In `Design/tokens.json`, dopo `accent-keys`, aggiungi `accent-bar` con la stessa famiglia OKLCH (L 0.52 chiaro / 0.76 scuro, C ≤ 0.15), tinta viola, distinta da ogni accento esistente; dopo `accent-on-ink-keys` aggiungi `accent-on-ink-bar` (L 0.70 su `ink` in chiaro, l'accento chiaro in scuro). `usage` nello stesso stile delle voci vicine, con «(provvisorio, da confermare da Matteo)».

```json
{
  "name": "accent-bar",
  "value": { "light": "#6b5fb5", "dark": "#a99cf0" },
  "usage": "Accento di Sbu Bar (provvisorio, da confermare da Matteo): solo il punto fermo `set` e il campo dell'icona (valore light). Famiglia OKLCH L 0.52/0.76, C ≤ 0.15: stesso peso per ogni app, cambia solo la tinta."
}
```

```json
{
  "name": "accent-on-ink-bar",
  "value": { "light": "#9a8de6", "dark": "#6b5fb5" },
  "usage": "Punto fermo di Sbu Bar dentro il blocco d'inchiostro della Chiusura: OKLCH L 0.70 su `ink` in light, l'accento light sul blocco chiaro in dark."
}
```

- [ ] **Step 2: genera e verifica i contrasti.**

Run: `python3 Tools/sync_tokens.py`
Expected: esce con 0. Se fallisce un contrasto, aggiusta solo la luminosità dei due valori e rilancia.

- [ ] **Step 3: scrivi `project.yml`** copiando la forma di `Apps/SbuKeys/project.yml`, con queste differenze: `name: SbuBar`, target `SbuBar`/`SbuBarTests`, `PRODUCT_BUNDLE_IDENTIFIER: dev.sbu.bar`, `INFOPLIST_KEY_CFBundleDisplayName: Sbu Bar`, entitlements con `com.apple.security.app-sandbox: false`, e il commento sopra i target:

```yaml
# Not sandboxed (ADR-0025): reading and moving other apps' menu bar items needs
# Accessibility and Screen Recording outside the sandbox. Distributed as a notarised .dmg.
```

- [ ] **Step 4: scrivi l'app minima.**

```swift
import SbuKit
import SwiftUI

@main
struct SbuBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("Sbu Bar")
                .padding(SbuTheme.space4)
                .environment(\.sbuAccent, .bar)
        } label: {
            Image(systemName: "menubar.rectangle")
                .accessibilityLabel(Text("Sbu Bar"))
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 5: test di fumo.**

```swift
@testable import SbuBar
import Foundation
import Testing

struct SmokeTests {
    @Test func bundleIdentifierIsDevSbuBar() {
        #expect(Bundle(identifier: "dev.sbu.bar") != nil)
    }
}
```

- [ ] **Step 6: README.** Una pagina: cosa fa Sbu Bar, perché è fuori dalla sandbox (ADR-0025), i permessi (Accessibilità, Registrazione schermo), e una sezione vuota «API di sistema non documentate» con la frase «Nessuna per ora».

- [ ] **Step 7: genera, compila, testa.**

Run: `cd Apps/SbuBar && xcodegen && xcodebuild test -project SbuBar.xcodeproj -scheme SbuBar -destination 'platform=macOS'`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: commit.**

```bash
git add Design/tokens.json Packages/SbuKit Apps/SbuBar
git commit -m "Sbu Bar: project, accent and menu bar shell"
```

`sync_tokens.py` aggiorna anche `../site/src/styles/tokens.css` nel repo del sito: committalo lì a parte, sul branch locale del sito, senza push.

(Il file `.xcodeproj` non si committa: controlla `.gitignore` come per le altre app.)

---

### Task 2: spike del riordino (risposta, non codice da tenere)

**Obiettivo:** rispondere a una domanda: **si può spostare un'icona della barra dei menu di un'altra app in una posizione scelta, in modo affidabile, senza che il puntatore dell'utente si muova visibilmente?** E quanto tempo serve per icona.

Questo task è uno spike: per la clean room il piano non prescrive la tecnica. Trovala tu dalla documentazione pubblica di Apple (Accessibilità: `AXUIElement`, attributi della barra dei menu; Quartz Event Services; `NSStatusItem`, `autosaveName`, preferenze di posizione) e da come macOS permette all'utente di riordinare a mano le icone (trascinamento con ⌘).

**Files:**
- Create: `Apps/SbuBar/Spike/` (cartella esclusa dal target dell'app in `project.yml`, o un target `SbuBarSpike` separato)
- Create: `Apps/SbuBar/Spike/FINDINGS.md`

- [ ] **Step 1:** scrivi un eseguibile minimo che elenca le icone della barra dei menu delle altre app (app, titolo o descrizione, posizione x) e lo stampa.
- [ ] **Step 2:** aggiungi un comando che sposta l'icona N subito a destra dell'icona M.
- [ ] **Step 3:** misura: riuscita su 20 tentativi, tempo medio, se il puntatore si vede muovere, cosa succede con il notch e con due schermi.
- [ ] **Step 4:** scrivi `FINDINGS.md`: tecnica usata con i link alla documentazione Apple, API non documentate usate (se ce ne sono) e perché non c'era un'alternativa pubblica, risultati delle misure, rischi.
- [ ] **Step 5:** commit con messaggio `Sbu Bar: arranger spike findings`. Poi FERMATI: Matteo prova lo spike sul suo Mac e decide se si va avanti.

---

### Task 3: identità di un'icona e modello delle sezioni

**Files:**
- Create: `Apps/SbuBar/SbuBar/Sections/ItemID.swift`
- Create: `Apps/SbuBar/SbuBar/Sections/Section.swift`
- Create: `Apps/SbuBar/SbuBar/Sections/Layout.swift`
- Create: `Apps/SbuBar/SbuBar/Sections/Move.swift`
- Test: `Apps/SbuBar/SbuBarTests/LayoutTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated struct ItemID: Hashable, Codable, Sendable { let bundleID: String; let name: String }`
  - `nonisolated enum Section: String, Codable, CaseIterable, Sendable { case shown, hidden, alwaysHidden }`
  - `nonisolated struct Layout: Codable, Equatable, Sendable { var order: [Section: [ItemID]] }` con `func section(of: ItemID) -> Section?`, `mutating func place(_: ItemID, in: Section, at: Int)`, `mutating func adopt(_ live: [ItemID])`, `func moves(from live: [ItemID]) -> [Move]`
  - `nonisolated struct Move: Equatable, Sendable { let item: ItemID; let after: ItemID? }` (`after == nil`: all'estrema sinistra della sezione mostrata)

Ordine visivo della barra, da sinistra a destra: Sempre nascoste, Nascoste, Mostrate. `live` è l'ordine reale da sinistra a destra.

- [ ] **Step 1: test che falliscono.**

```swift
@testable import SbuBar
import Testing

struct LayoutTests {
    let a = ItemID(bundleID: "com.example.a", name: "A")
    let b = ItemID(bundleID: "com.example.b", name: "B")
    let c = ItemID(bundleID: "com.example.c", name: "C")

    @Test func adoptPutsNewItemsInShownAndKeepsKnownOnes() {
        var layout = Layout(order: [.hidden: [b]])
        layout.adopt([a, b, c])
        #expect(layout.section(of: b) == .hidden)
        #expect(layout.order[.shown] == [a, c])
    }

    @Test func adoptKeepsTheSlotOfAnItemThatIsGone() {
        var layout = Layout(order: [.shown: [a, b, c]])
        layout.adopt([a, c])
        #expect(layout.order[.shown] == [a, b, c])
    }

    @Test func placeMovesAnItemBetweenSections() {
        var layout = Layout(order: [.shown: [a, b, c]])
        layout.place(b, in: .hidden, at: 0)
        #expect(layout.order[.shown] == [a, c])
        #expect(layout.order[.hidden] == [b])
    }

    @Test func noMovesWhenLiveMatchesLayout() {
        let layout = Layout(order: [.alwaysHidden: [c], .hidden: [b], .shown: [a]])
        #expect(layout.moves(from: [c, b, a]).isEmpty)
    }

    @Test func movesBringLiveOrderToLayout() {
        let layout = Layout(order: [.alwaysHidden: [c], .hidden: [b], .shown: [a]])
        let moves = layout.moves(from: [a, b, c])
        var live = [a, b, c]
        for move in moves {
            live.removeAll { $0 == move.item }
            let index = move.after.flatMap { live.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
            live.insert(move.item, at: index)
        }
        #expect(live == [c, b, a])
    }

    @Test func movesIgnoreItemsThatAreNotLive() {
        let layout = Layout(order: [.hidden: [b], .shown: [a, c]])
        #expect(layout.moves(from: [a]).isEmpty)
    }
}
```

- [ ] **Step 2: verifica che falliscano.**

Run: `cd Apps/SbuBar && xcodegen && xcodebuild test -project SbuBar.xcodeproj -scheme SbuBar -destination 'platform=macOS' -only-testing:SbuBarTests/LayoutTests`
Expected: FAIL, `cannot find 'Layout' in scope`.

- [ ] **Step 3: implementa.** Un file per tipo. `moves(from:)`: calcola l'ordine desiderato (`alwaysHidden + hidden + shown`, filtrato agli elementi presenti in `live`), poi scorre da sinistra a destra e, per ogni posizione in cui `live` differisce, produce `Move(item: desiderato[i], after: i == 0 ? nil : desiderato[i-1])` e applica lo spostamento alla copia di `live`. Restituisce la lista minima prodotta così.

```swift
nonisolated struct Layout: Codable, Equatable, Sendable {
    var order: [Section: [ItemID]] = [:]

    private static let visualOrder: [Section] = [.alwaysHidden, .hidden, .shown]

    func section(of item: ItemID) -> Section? {
        Section.allCases.first { order[$0, default: []].contains(item) }
    }

    mutating func place(_ item: ItemID, in section: Section, at index: Int) {
        for key in Section.allCases { order[key]?.removeAll { $0 == item } }
        var items = order[section, default: []]
        items.insert(item, at: min(max(index, 0), items.count))
        order[section] = items
    }

    mutating func adopt(_ live: [ItemID]) {
        for item in live where section(of: item) == nil {
            order[.shown, default: []].append(item)
        }
    }

    func moves(from live: [ItemID]) -> [Move] {
        let present = Set(live)
        let desired = Self.visualOrder.flatMap { order[$0, default: []] }.filter(present.contains)
        var current = live.filter { desired.contains($0) }
        var moves: [Move] = []
        for (index, item) in desired.enumerated() where current[index] != item {
            let after = index == 0 ? nil : desired[index - 1]
            moves.append(Move(item: item, after: after))
            current.removeAll { $0 == item }
            current.insert(item, at: index)
        }
        return moves
    }
}
```

- [ ] **Step 4: verifica che passino.** Stesso comando dello Step 2. Expected: PASS.
- [ ] **Step 5: commit.** `git commit -m "Sbu Bar: item identity and section layout"`

---

### Task 4: archivio JSON versionato con copia di riserva

**Files:**
- Create: `Apps/SbuBar/SbuBar/Store/Settings.swift`
- Create: `Apps/SbuBar/SbuBar/Store/SettingsStore.swift`
- Test: `Apps/SbuBar/SbuBarTests/SettingsStoreTests.swift`

**Interfaces:**
- Consumes: `Layout` (Task 3).
- Produces:
  - `nonisolated struct Settings: Codable, Equatable, Sendable { static let currentVersion = 1; var version: Int; var layout: Layout }` con `init(layout: Layout = Layout())`
  - `nonisolated struct SettingsStore: Sendable { init(directory: URL); func load() -> Settings; func save(_: Settings) throws }`. File `settings.json` e `settings.backup.json` in `directory`. `save` scrive prima la copia di riserva del file attuale, poi il nuovo in modo atomico. `load` legge `settings.json`; se manca o è illeggibile prova la copia di riserva; se manca anche quella restituisce `Settings()`.

- [ ] **Step 1: test che falliscono.**

```swift
@testable import SbuBar
import Foundation
import Testing

struct SettingsStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let item = ItemID(bundleID: "com.example.a", name: "A")

    @Test func loadWithoutFilesGivesDefaults() {
        #expect(SettingsStore(directory: directory).load() == Settings())
    }

    @Test func saveThenLoadRoundTrips() throws {
        let store = SettingsStore(directory: directory)
        let settings = Settings(layout: Layout(order: [.hidden: [item]]))
        try store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func corruptFileFallsBackToBackup() throws {
        let store = SettingsStore(directory: directory)
        let first = Settings(layout: Layout(order: [.hidden: [item]]))
        try store.save(first)
        try store.save(Settings(layout: Layout(order: [.shown: [item]])))
        try Data("{".utf8).write(to: directory.appending(path: "settings.json"))
        #expect(store.load() == first)
    }

    @Test func savedFileCarriesTheVersion() throws {
        let store = SettingsStore(directory: directory)
        try store.save(Settings())
        let data = try Data(contentsOf: directory.appending(path: "settings.json"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["version"] as? Int == Settings.currentVersion)
    }
}
```

- [ ] **Step 2: verifica che falliscano** (`-only-testing:SbuBarTests/SettingsStoreTests`). Expected: FAIL, `cannot find 'SettingsStore'`.
- [ ] **Step 3: implementa.**

```swift
nonisolated struct SettingsStore: Sendable {
    let directory: URL
    private var file: URL { directory.appending(path: "settings.json") }
    private var backup: URL { directory.appending(path: "settings.backup.json") }

    func load() -> Settings {
        for url in [file, backup] {
            if let data = try? Data(contentsOf: url),
               let settings = try? JSONDecoder().decode(Settings.self, from: data) {
                return settings
            }
        }
        return Settings()
    }

    func save(_ settings: Settings) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let current = try? Data(contentsOf: file),
           (try? JSONDecoder().decode(Settings.self, from: current)) != nil {
            try current.write(to: backup, options: .atomic)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: file, options: .atomic)
    }
}
```

Nota: `[Section: [ItemID]]` con chiavi `String`-raw si codifica come array alterno in JSON; per un file leggibile codifica `order` come dizionario con chiavi `rawValue` (implementa `Codable` di `Layout` a mano con un `[String: [ItemID]]`), e aggiungi un test che il JSON contenga la chiave `"hidden"`.

- [ ] **Step 4: verifica che passino.** Expected: PASS.
- [ ] **Step 5: commit.** `git commit -m "Sbu Bar: versioned settings file with backup"`

---

### Task 5: lettura delle icone dietro un protocollo

**Files:**
- Create: `Apps/SbuBar/SbuBar/Items/MenuBarItem.swift`
- Create: `Apps/SbuBar/SbuBar/Items/MenuBarReading.swift`
- Create: `Apps/SbuBar/SbuBar/Items/SystemMenuBarReader.swift`
- Create: `Apps/SbuBar/SbuBar/Items/ItemsModel.swift`
- Test: `Apps/SbuBar/SbuBarTests/ItemsModelTests.swift`

**Interfaces:**
- Consumes: `ItemID`, `Layout` (Task 3).
- Produces:
  - `nonisolated struct MenuBarItem: Identifiable, Equatable, Sendable { let id: ItemID; let title: String; let frame: CGRect }`
  - `protocol MenuBarReading: Sendable { func items() async -> [MenuBarItem] }` (ordine da sinistra a destra)
  - `struct SystemMenuBarReader: MenuBarReading` (implementazione reale, tecnica dallo spike del Task 2)
  - `@Observable final class ItemsModel { init(reader: any MenuBarReading); private(set) var items: [MenuBarItem]; func refresh() async; var liveOrder: [ItemID] }`

- [ ] **Step 1: test che falliscono.**

```swift
@testable import SbuBar
import CoreGraphics
import Testing

struct FakeReader: MenuBarReading {
    let result: [MenuBarItem]
    func items() async -> [MenuBarItem] { result }
}

@MainActor
struct ItemsModelTests {
    let wifi = MenuBarItem(id: ItemID(bundleID: "com.apple.controlcenter", name: "WiFi"), title: "Wi-Fi", frame: CGRect(x: 900, y: 0, width: 24, height: 24))
    let app = MenuBarItem(id: ItemID(bundleID: "com.example.app", name: "Item-0"), title: "App", frame: CGRect(x: 800, y: 0, width: 24, height: 24))

    @Test func refreshPublishesItemsInLeftToRightOrder() async {
        let model = ItemsModel(reader: FakeReader(result: [wifi, app]))
        await model.refresh()
        #expect(model.liveOrder == [app.id, wifi.id])
    }

    @Test func refreshWithNoItemsIsEmpty() async {
        let model = ItemsModel(reader: FakeReader(result: []))
        await model.refresh()
        #expect(model.items.isEmpty)
    }
}
```

- [ ] **Step 2: verifica che falliscano.** Expected: FAIL, `cannot find 'ItemsModel'`.
- [ ] **Step 3: implementa `ItemsModel`** ordinando per `frame.minX` (il lettore reale può restituirli in qualunque ordine):

```swift
import Observation

@Observable
final class ItemsModel {
    private let reader: any MenuBarReading
    private(set) var items: [MenuBarItem] = []

    init(reader: any MenuBarReading) { self.reader = reader }

    var liveOrder: [ItemID] { items.map(\.id) }

    func refresh() async {
        items = await reader.items().sorted { $0.frame.minX < $1.frame.minX }
    }
}
```

- [ ] **Step 4: implementa `SystemMenuBarReader`** con la tecnica scelta nello spike (Task 2, `Spike/FINDINGS.md`): solo API pubbliche, o le non documentate elencate lì, ognuna aggiunta alla sezione «API di sistema non documentate» del README. L'identità `ItemID.name` deve restare stabile se l'app si riavvia: usa un identificatore dell'elemento (descrizione o titolo di Accessibilità) e, se più icone della stessa app non ne hanno uno, l'indice tra le icone di quell'app.
- [ ] **Step 5: verifica che passino** e prova a mano: un pulsante provvisorio nel `MenuBarExtra` che chiama `refresh()` e mostra l'elenco dei titoli. Le icone che vedi nella barra devono comparire tutte, in ordine.
- [ ] **Step 6: commit.** `git commit -m "Sbu Bar: read menu bar items behind a protocol"`

---

## Dopo questo piano

Con lo spike approvato da Matteo e i Task 3–5 verdi, il piano 2 copre `Arranger` reale con `MenuBarMoving`, `Reveal` e `Welcome`/`Settings`; il piano 3 `Strip`, `Search`, `Appearance`; il piano 4 `Profiles`, `Triggers` (con MapKit), gruppi, `Displays`, icona e .dmg.
