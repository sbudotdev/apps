import Foundation

extension ChoreDraft {
    init(chore: Chore) {
        self.init(lastDone: chore.lastDone)
        name = chore.name
        frequencyValue = chore.frequency.value
        frequencyUnit = chore.frequency.unit
        effort = chore.effort
        isOneOff = chore.isOneOff
        notes = chore.notes
    }
}
