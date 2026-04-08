import Foundation
import SwiftData

@Model
public final class SDHealthSnapshot {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var cycleCount: Int
    public var healthPercent: Double
    public var maxMah: Int?
    public var designMah: Int?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        cycleCount: Int,
        healthPercent: Double,
        maxMah: Int? = nil,
        designMah: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cycleCount = cycleCount
        self.healthPercent = healthPercent
        self.maxMah = maxMah
        self.designMah = designMah
    }
}
