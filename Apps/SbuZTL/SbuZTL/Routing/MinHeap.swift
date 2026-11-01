/// The binary heap behind A*.
nonisolated struct MinHeap {
    private var items: [(key: Double, value: Int)] = []

    mutating func push(_ key: Double, _ value: Int) {
        items.append((key, value))
        var i = items.count - 1
        while i > 0, items[(i - 1) / 2].key > items[i].key {
            items.swapAt(i, (i - 1) / 2)
            i = (i - 1) / 2
        }
    }

    mutating func pop() -> (key: Double, value: Int)? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < items.count, items[l].key < items[m].key { m = l }
                if r < items.count, items[r].key < items[m].key { m = r }
                if m == i { break }
                items.swapAt(i, m)
                i = m
            }
        }
        return top
    }
}
