import Foundation
import SwiftData

@Model
final class Tag: @unchecked Sendable {
    #Unique<Tag>([\.id])

    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify)
    var pins: [Pin] = []

    init(
        id: UUID = UUID(),
        name: String
    ) {
        self.id = id
        self.name = name
    }
}


