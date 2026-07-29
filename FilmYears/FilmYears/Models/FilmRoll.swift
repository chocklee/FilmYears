import SwiftData
import Foundation

@Model
final class FilmRoll {
    var year: Int
    var createdAt: Date
    var isInitialized: Bool

    @Relationship(deleteRule: .cascade) var frames: [FilmFrame] = []

    init(year: Int) {
        self.year = year
        self.createdAt = .now
        self.isInitialized = false
    }
}

extension FilmRoll {
    var filledCount: Int { frames.filter(\.isFilled).count }
    var totalCount: Int { frames.count }
    var fillRatio: Double { totalCount > 0 ? Double(filledCount) / Double(totalCount) : 0 }

    var yearFormatted: String {
        year.formatted(.number.grouping(.never))
    }

    var frameCountFormatted: String {
        "\(filledCount.formatted(.number.grouping(.never)))/\(totalCount.formatted(.number.grouping(.never)))"
    }
}
