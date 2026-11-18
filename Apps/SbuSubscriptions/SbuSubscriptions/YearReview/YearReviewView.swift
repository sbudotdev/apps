import SbuKit
import SwiftUI

/// "Il tuo 2026 in abbonamenti", in a sheet: what you paid in the year, in each currency, then what renews in January
/// and a nudge to cancel what you no longer use before it does.
struct YearReviewView: View {
    let review: YearReview

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    figure
                        .padding(.horizontal, SbuTheme.space4)
                        .padding(.vertical, SbuTheme.gridCell)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sbuPaper(grid: true)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if !review.isEmpty {
                    Section {
                        if review.januaryRenewals.isEmpty {
                            Text("Nessun rinnovo a gennaio")
                                .foregroundStyle(SbuTheme.inkMuted)
                        }
                        ForEach(review.januaryRenewals, id: \.self) { renewal in
                            LabeledContent {
                                Text(renewal.amount.value, format: .currency(code: renewal.amount.currencyCode))
                            } label: {
                                Text(renewal.name)
                                Text(renewal.date, format: .dateTime.day().month(.wide))
                            }
                        }
                    } header: {
                        Text("Si rinnovano a gennaio")
                    } footer: {
                        Text("Ce n'è uno che non usi più? Annullalo prima che si rinnovi.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(SbuTheme.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                        .accessibilityIdentifier("closeReviewSheet")
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder private var figure: some View {
        VStack(alignment: .leading, spacing: SbuTheme.gridCell) {
            SbuScreenTitle("Il tuo \(review.year) in abbonamenti", cartiglio: "Sbu · \(String(localized: "Abbonamenti")) · \(review.year)")
                // Longer than a tab's title, it wraps on two lines: never squeezed to one.
                .fixedSize(horizontal: false, vertical: true)
            if let first = review.spent.first {
                SbuFigure(value: first.value.formatted(.currency(code: first.currencyCode)), context: Text(context))
            } else {
                SbuEmpty(sentence: "Nel \(review.year) non hai pagato abbonamenti.")
            }
        }
    }

    /// "spesi nel 2026", then the other currencies, never converted: each subscription in its own.
    private var context: LocalizedStringKey {
        let others = review.spent.dropFirst().map { $0.value.formatted(.currency(code: $0.currencyCode)) }
        return others.isEmpty ? "spesi nel \(review.year)" : "spesi nel \(review.year) · più \(others.formatted(.list(type: .and)))"
    }
}

#Preview("Light") {
    YearReviewView(review: YearReview(year: 2026, entries: Subscription.demo().map { $0.yearReviewEntry() }, through: .now,
                                    mainCurrency: "EUR", calendar: .current))
        .environment(\.sbuAccent, .subscriptions)
}

#Preview("Dark") {
    YearReviewView(review: YearReview(year: 2026, entries: [], through: .now, mainCurrency: "EUR", calendar: .current))
        .environment(\.sbuAccent, .subscriptions)
        .preferredColorScheme(.dark)
}
