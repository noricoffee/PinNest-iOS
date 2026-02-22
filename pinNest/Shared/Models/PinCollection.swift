import Foundation
import SwiftData

@Model
final class PinCollection {
    #Unique<PinCollection>([\.id])

    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var pins: [Pin] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

extension PinCollection: @unchecked Sendable {}
