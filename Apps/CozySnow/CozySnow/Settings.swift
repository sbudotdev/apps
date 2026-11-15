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

    private init() {
        values = SnowSettings(saved: UserDefaults.standard.data(forKey: Self.key))
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
                Section("Nevicata") {
                    slider("Quantità di fiocchi", $settings.values.flakeCount, 30...800, "%.0f")
                    slider("Dimensione", $settings.values.flakeSize, 0.5...2.5, "%.1f×")
                    slider("Velocità di caduta", $settings.values.fallSpeed, 0.3...2.5, "%.1f×")
                    slider("Vento", $settings.values.wind, 0...80, "%.0f")
                }
                Section("Cursore") {
                    slider("Raggio", $settings.values.cursorRadius, 20...250, "%.0f pt")
                    slider("Forza", $settings.values.cursorRepel, 0...6000, "%.0f")
                }
                Section("Neve posata") {
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
                Section {
                    Toggle("Apri al login", isOn: $openAtLogin)
                        .onChange(of: openAtLogin) { _, on in setOpenAtLogin(on) }
                    LabeledContent("Valori predefiniti") {
                        Button("Ripristina…") { confirmsReset = true }
                    }
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
            Text("Tutte le impostazioni della neve tornano come al primo avvio.")
        }
        .frame(width: 440, height: 680)   // il contenuto è più alto: si scorre
    }

    /// Titolo e cartiglio, come `SbuScreenTitle` nelle app.
    private var header: some View {
        VStack(alignment: .leading, spacing: Quaderno.space1) {
            Text("Neve")
                .font(Quaderno.titleFont)
                .foregroundStyle(Quaderno.ink.color)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: cartiglio)
                .font(Quaderno.cartiglioFont)
                .tracking(Quaderno.cartiglioSize * Quaderno.cartiglioTracking)
                .foregroundStyle(Quaderno.inkMuted.color)
        }
        .padding(.horizontal, Quaderno.space6)
        .padding(.top, Quaderno.space4)
    }

    /// `SBU · NEVE · DOM 15 NOV`: solo metadati, maiuscolo nella stringa (come in SbuKit).
    private var cartiglio: String {
        let day = Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "it_IT")))
        return "Sbu · Neve · \(day)".uppercased(with: Locale(identifier: "it_IT"))
    }

    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ format: String) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range)
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
            }
            .frame(width: 230)
        }
    }

    private func setOpenAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        guard on != (service.status == .enabled) else { return }   // già nello stato giusto
        do {
            if on { try service.register() } else { try service.unregister() }
        } catch {
            // Di solito serve l'approvazione dell'utente: apriamo le Impostazioni di Sistema giuste.
            NSLog("CozySnow: avvio al login non riuscito: \(error)")
            SMAppService.openSystemSettingsLoginItems()
        }
        openAtLogin = service.status == .enabled
    }
}
