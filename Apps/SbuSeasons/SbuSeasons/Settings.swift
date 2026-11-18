import SwiftUI
import ServiceManagement

/// Tutte le impostazioni regolabili, con i valori predefiniti.
/// Si salvano su disco come un unico blocco JSON in UserDefaults.
nonisolated struct SnowSettings: Codable, Equatable {
    // Nevicata
    var flakeCount = 260.0      // fiocchi su uno schermo da 1440×900 (scalato sull'area)
    var flakeSize = 1.0         // moltiplicatore
    var fallSpeed = 1.0         // moltiplicatore
    var wind = 14.0             // pt/s
    // Cursore
    var cursorRadius = 90.0     // pt
    var cursorRepel = 2200.0    // pt/s²
    // Accumulo
    var accumulate = true
    var groundSnow = true       // neve sopra il Dock (nome storico, cambiarlo azzererebbe i salvataggi)
    var growth = 0.9            // neve aggiunta per fiocco posato
    var maxPile = 16.0          // pt (sul Dock arriva a 1,75×)
    var toolbarCornerRadius = 34.0  // pt: angoli delle app con barra strumenti (Finder, Safari, Note…)
    var windowCornerRadius = 20.0   // pt: angoli delle altre app (IntelliJ, Chrome…)
    var dockInset = 7.0         // pt: il rettangolo del Dock dato da macOS ha un margine sopra la barra visibile
    // Suoni (SoundBoard): spenti finché non li accendi
    var sounds = false
    var soundVolume = 60.0      // %
    // Notte: schermo più scuro e la candela, dalle `nightStart` al mattino o sempre
    var night = NightMode.off
    var nightStart = 22         // ora
    // Dietro le finestre: gli effetti sulla scrivania, sotto le finestre delle app
    var behindWindows = false
}

extension SnowSettings {
    /// Parte dai valori predefiniti e ci sovrappone quelli salvati, uno per uno: un'impostazione
    /// nuova prende il suo predefinito, e un valore illeggibile non fa perdere gli altri.
    init(saved data: Data?) {
        self.init()
        let saved = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        for (key, value) in saved {
            guard var merged = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any]
            else { return }
            merged[key] = value
            if let data = try? JSONSerialization.data(withJSONObject: merged),
               let decoded = try? JSONDecoder().decode(SnowSettings.self, from: data) {
                self = decoded
            }
        }
    }
}

/// Il "contenitore" condiviso: la finestra lo modifica, la scena lo legge a ogni frame.
/// `@Observable` fa sì che SwiftUI si aggiorni da solo quando cambia.
@Observable
final class Settings {
    static let shared = Settings()
    private static let key = "settings"

    var values: SnowSettings {
        didSet { UserDefaults.standard.set(try? JSONEncoder().encode(values), forKey: Self.key) }
    }

    /// La stagione scelta dal menu ❄︎ o dalle Impostazioni, salvata a parte: "Ripristina…" non la cambia.
    var seasonID: String {
        didSet { UserDefaults.standard.set(seasonID, forKey: "season") }
    }
    var season: any Season { Seasons.named(seasonID) }

    /// Chiama `action` dopo ogni cambio di stagione, da qualunque parte arrivi (menu ❄︎ o Impostazioni).
    func observeSeason(_ action: @escaping @MainActor @Sendable () -> Void) {
        // withObservationTracking avvisa una volta sola, e prima del cambio: dopo, si riascolta.
        withObservationTracking { _ = seasonID } onChange: {
            Task { @MainActor in
                action()
                self.observeSeason(action)
            }
        }
    }

    private init() {
        values = SnowSettings(saved: UserDefaults.standard.data(forKey: Self.key))
        seasonID = UserDefaults.standard.string(forKey: "season") ?? Seasons.all[0].id
    }

    func reset() { values = SnowSettings() }
}

/// La finestra delle impostazioni (si apre dal menu ❄︎ → Impostazioni…).
/// Quaderno: titolo e cartiglio su carta, poi il `Form` di sistema con i controlli nativi in inchiostro.
struct SettingsView: View {
    @Bindable private var settings = Settings.shared
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var confirmsReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Form {
                Section {
                    // Le stesse voci, nello stesso ordine, del sottomenu ❄︎ → Effetto.
                    Picker("Effetto", selection: $settings.seasonID) {
                        ForEach(Seasons.all, id: \.id) { season in
                            Label(season.title, systemImage: season.symbol).tag(season.id)
                        }
                    }
                    Toggle("Dietro le finestre", isOn: $settings.values.behindWindows)
                } footer: {
                    Text("Dietro le finestre: gli effetti restano sulla scrivania, sotto le finestre delle app.")
                        .foregroundStyle(Quaderno.inkMuted.color)
                }
                Section("Caduta") {
                    slider("Quantità", $settings.values.flakeCount, Density.range, "%.0f")
                    slider("Dimensione", $settings.values.flakeSize, 0.5...2.5, "%.1f×")
                    slider("Velocità di caduta", $settings.values.fallSpeed, 0.3...2.5, "%.1f×")
                    slider("Vento", $settings.values.wind, 0...80, "%.0f")
                }
                Section("Cursore") {
                    slider("Raggio", $settings.values.cursorRadius, 20...250, "%.0f pt")
                    slider("Forza", $settings.values.cursorRepel, 0...6000, "%.0f")
                }
                Section("Dove si posa") {
                    Toggle("Sulle finestre", isOn: $settings.values.accumulate)
                    Toggle("Sul Dock", isOn: $settings.values.groundSnow)
                    if settings.values.groundSnow && !AXIsProcessTrusted() {
                        LabeledContent {
                            Button("Apri Accessibilità…") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            }
                        } label: {
                            Text("Per vedere dov'è il Dock serve il permesso Accessibilità.")
                                .foregroundStyle(Quaderno.inkMuted.color)
                        }
                    }
                    slider("Velocità", $settings.values.growth, 0.1...3, "%.1f")
                    slider("Altezza massima", $settings.values.maxPile, 4...40, "%.0f pt")
                    slider("Più in basso sul Dock", $settings.values.dockInset, -10...25, "%.0f pt")
                }
                Section {
                    slider("Con barra strumenti", $settings.values.toolbarCornerRadius, 0...60, "%.0f pt")
                    slider("Altre app", $settings.values.windowCornerRadius, 0...60, "%.0f pt")
                } header: {
                    Text("Angoli delle finestre")
                } footer: {
                    Text("Finder, Safari e Note hanno angoli più tondi di Chrome. Se la neve resta sospesa sugli angoli, aumenta; se entra nella finestra, diminuisci.")
                        .foregroundStyle(Quaderno.inkMuted.color)
                }
                Section("Suoni") {
                    Toggle("Riproduci i suoni", isOn: $settings.values.sounds)
                    slider("Volume", $settings.values.soundVolume, 0...100, "%.0f%%")
                        .disabled(!settings.values.sounds)
                }
                .onChange(of: settings.values.sounds) { SoundBoard.shared.settingsChanged() }
                .onChange(of: settings.values.soundVolume) { SoundBoard.shared.settingsChanged() }
                Section {
                    Picker("Candela e luce bassa", selection: $settings.values.night) {
                        Text("Mai").tag(NightMode.off)
                        Text("Di sera").tag(NightMode.late)
                        Text("Sempre").tag(NightMode.always)
                    }
                    Picker("Dalle", selection: $settings.values.nightStart) {
                        ForEach([18, 19, 20, 21, 22, 23, 0, 1, 2], id: \.self) { hour in
                            Text(verbatim: String(format: "%02d:00", hour)).tag(hour)
                        }
                    }
                    .disabled(settings.values.night != .late)
                } header: {
                    Text("Notte")
                } footer: {
                    Text("Lo schermo si scurisce un po' e in basso a destra si accende una candela. Di sera vuol dire dall'ora scelta fino alle 6.")
                        .foregroundStyle(Quaderno.inkMuted.color)
                }
                Section {
                    Toggle("Apri al login", isOn: $openAtLogin)
                        .onChange(of: openAtLogin) { _, on in setOpenAtLogin(on) }
                    LabeledContent("Valori predefiniti") {
                        Button("Ripristina…") { confirmsReset = true }
                    }
                } footer: {
                    // Il credito a chi ha scritto l'app da cui nasce Sbu Seasons (Credits.swift).
                    VStack(alignment: .leading, spacing: Quaderno.space1) {
                        Text(verbatim: Credits.sentence)
                            .foregroundStyle(Quaderno.inkMuted.color)
                        Link(Credits.linkTitle, destination: Credits.url)
                            .foregroundStyle(Quaderno.ink.color)   // i link sono in inchiostro, non nel blu di sistema
                            .underline()
                    }
                    .padding(.top, Quaderno.space4)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .clipped()   // le righe che scorrono non passano sotto il titolo
        }
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
        .toggleStyle(.switch)
        .confirmationDialog("Ripristinare i valori predefiniti?", isPresented: $confirmsReset) {
            Button("Ripristina", role: .destructive) { settings.reset() }
        } message: {
            Text("Tutte le impostazioni tornano come al primo avvio.")
        }
        // A multipli della cella del reticolo (grid-cell). Il contenuto è più alto: si scorre.
        .frame(width: Quaderno.gridCell * 19, height: Quaderno.gridCell * 28)
    }

    /// Titolo e cartiglio, come `SbuScreenTitle` nelle app.
    private var header: some View {
        VStack(alignment: .leading, spacing: Quaderno.space1) {
            Text(verbatim: SbuSeasonsApp.name)
                .font(Quaderno.titleFont)
                .foregroundStyle(Quaderno.ink.color)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: Self.cartiglio(on: .now))
                .font(Quaderno.cartiglioFont)
                .tracking(Quaderno.cartiglioSize * Quaderno.cartiglioTracking)
                .foregroundStyle(Quaderno.inkMuted.color)
        }
        .padding(.horizontal, Quaderno.space6)
        .padding(.top, Quaderno.space4)
    }

    /// `SBU · SEASONS · DOM 15 NOV`, la data nella lingua dell'app: solo metadati, maiuscolo nella stringa (come in SbuKit).
    static func cartiglio(on date: Date) -> String {
        // La lingua dell'app (italiano o inglese), non quella del Mac: tutto il cartiglio nella stessa lingua.
        let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "it")
        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(locale))
        // "Sbu Seasons" → "Sbu · Seasons": il marchio una volta sola, come nelle app iPhone.
        let name = SbuSeasonsApp.name.replacing(#/^Sbu /#, with: "")
        return "Sbu · \(name) · \(day)".uppercased(with: locale)
    }

    private func slider(_ title: LocalizedStringKey, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ format: String) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range)
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .frame(width: Quaderno.gridCell * 3, alignment: .trailing)
            }
            .frame(width: Quaderno.gridCell * 10)
        }
    }

    private func setOpenAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        guard on != (service.status == .enabled) else { return }   // già nello stato giusto
        do {
            if on { try service.register() } else { try service.unregister() }
        } catch {
            // Di solito serve l'approvazione dell'utente: apriamo le Impostazioni di Sistema giuste.
            NSLog("Sbu Seasons: avvio al login non riuscito: \(error)")
            SMAppService.openSystemSettingsLoginItems()
        }
        openAtLogin = service.status == .enabled
    }
}

/// Con il bundle id cambiano anche i UserDefaults dell'app (README, "Dal vecchio nome").
/// Al primo avvio con il nome nuovo, neve accesa o spenta e impostazioni si copiano dal nome vecchio.
nonisolated enum PreviousDefaults {
    /// Dal più recente: il bundle id provvisorio (MGS-416), poi quello della versione di Simone.
    static let domains = ["dev.sbu.cozysnow", "local.cozysnow"]
    static let keys = ["settings", "isSnowing"]

    static func migrate(into defaults: UserDefaults = .standard, from domains: [String] = domains) {
        for key in keys where defaults.object(forKey: key) == nil {
            let value = domains.lazy.compactMap { UserDefaults(suiteName: $0)?.object(forKey: key) }.first
            if let value { defaults.set(value, forKey: key) }
        }
    }
}
