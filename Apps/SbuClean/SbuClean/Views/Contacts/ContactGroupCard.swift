import SbuKit
import SwiftUI

/// One person saved more than once: every copy with its numbers and addresses, the one kept
/// first, and "Unisci".
struct ContactGroupCard: View {
    let group: [ContactCard]
    let merge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            ForEach(Array(group.enumerated()), id: \.element.id) { index, contact in
                HStack(alignment: .firstTextBaseline, spacing: SbuTheme.space2) {
                    SbuRowMark(filled: index == 0)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(contact.name.isEmpty ? String(localized: "Senza nome") : contact.name)
                            .font(SbuTheme.headline)
                            .foregroundStyle(SbuTheme.ink)
                        ForEach(contact.phones + contact.emails, id: \.self) { detail in
                            Text(verbatim: detail)
                                .font(SbuTheme.subheadline)
                                .foregroundStyle(SbuTheme.inkMuted)
                        }
                        if index == 0 {
                            Text("Resta")
                                .font(SbuTheme.subheadline)
                                .foregroundStyle(SbuTheme.inkMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }

            Button("Unisci", action: merge)
                .buttonStyle(SbuFieldPillStyle())
        }
        .padding(SbuTheme.space3)
        .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                .strokeBorder(SbuTheme.line, lineWidth: SbuTheme.hairline)
        }
    }
}

#Preview("Light") {
    ContactGroupCard(group: [
        ContactCard(id: "1", name: "Giulia Rossi", phones: ["+39 333 123 4567"], emails: ["giulia.rossi@example.com"]),
        ContactCard(id: "2", name: "Giulia", phones: ["333 1234567"]),
    ]) {}
    .padding()
}

#Preview("Dark") {
    ContactGroupCard(group: [
        ContactCard(id: "1", name: "Giulia Rossi", phones: ["+39 333 123 4567"]),
        ContactCard(id: "2", name: "Giulia", phones: ["333 1234567"]),
    ]) {}
    .padding()
    .preferredColorScheme(.dark)
}
