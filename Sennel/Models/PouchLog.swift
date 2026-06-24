import SwiftData
import Foundation

@Model
final class PouchLog {
    var timestamp: Date
    var brand: String?      // optional, neutral/factual per design doc §6 — never promotional
    var strength: String?

    init(timestamp: Date = .now, brand: String? = nil, strength: String? = nil) {
        self.timestamp = timestamp
        self.brand = brand
        self.strength = strength
    }
}
