import ManagedSettings
import ManagedSettingsUI
import SbuKit
import SwiftUI
import UIKit

/// The Sbu Shield over an app: paper and ink. An Intenzione's Shield counts today's openings and
/// can open the app; while everything is blocked the Shield only closes.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let defaults = UserDefaults(suiteName: "group.dev.sbu.social") ?? .standard

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration(for: application)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(for: application)
    }

    private func configuration(for application: Application) -> ShieldConfiguration {
        let now = Date.now
        let name = application.localizedDisplayName
        switch ShieldSettings.load(from: defaults).kind(for: application.token, now: now) {
        case .session:
            return shield(title: name.map { String(localized: "\($0) è bloccata") } ?? String(localized: "App bloccata"),
                          subtitle: String(localized: "Blocco in corso. Torna a quello che stavi facendo."))
        case .intention(let intention):
            remember(name, for: intention)
            let opens = intention.opens(on: Day(now))
            let length = Duration.seconds(intention.minutes * 60).formatted(.units(allowed: [.minutes], width: .wide))
            let streak = Tally.load(from: defaults).streak(on: Day(now))
            let count = String(localized: "Aperture oggi: \(opens) su \(intention.maxOpens). Giorni di serie: \(streak).")
            let warning = String(localized: "Le hai finite: se la apri, oggi non conta per la serie.")
            return shield(title: name ?? String(localized: "App schermata"),
                          subtitle: opens < intention.maxOpens ? count : count + " " + warning,
                          open: String(localized: "Apri per \(length)"))
        case .plain:
            return shield(title: name.map { String(localized: "\($0) è schermata") } ?? String(localized: "App schermata"), subtitle: nil)
        }
    }

    /// Only the Shield can read an app's name: the Intenzione keeps it for the notification.
    private func remember(_ name: String?, for intention: Intention) {
        guard let name, name != intention.name else { return }
        ShieldSettings.update(in: defaults) { settings in
            guard let index = settings.intentions.firstIndex(where: { $0.id == intention.id }) else { return }
            settings.intentions[index].name = name
        }
    }

    private func shield(title: String, subtitle: String?, open: String? = nil) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: UIColor(SbuTheme.paper),
            icon: UIImage(systemName: "shield"),
            title: .init(text: title, color: UIColor(SbuTheme.ink)),
            subtitle: subtitle.map { .init(text: $0, color: UIColor(SbuTheme.inkMuted)) },
            primaryButtonLabel: .init(text: String(localized: "Chiudi"), color: UIColor(SbuTheme.paper)),
            primaryButtonBackgroundColor: UIColor(SbuTheme.ink),
            secondaryButtonLabel: open.map { .init(text: $0, color: UIColor(SbuTheme.ink)) }
        )
    }
}
