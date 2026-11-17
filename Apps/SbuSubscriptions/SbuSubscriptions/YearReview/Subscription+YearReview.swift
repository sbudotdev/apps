import Foundation

extension Subscription {
    /// This subscription as the year review reads it; a paused or cancelled one stops on the day it stopped.
    func yearReviewEntry(calendar: Calendar = .current) -> YearReview.Entry {
        YearReview.Entry(name: name, currencyCode: currencyCode, schedule: schedule, stoppedOn: stoppedOn, isActive: status == .active) {
            self.price(on: $0, calendar: calendar)
        }
    }
}
