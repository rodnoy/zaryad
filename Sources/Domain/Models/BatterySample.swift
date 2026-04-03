import Foundation

public struct BatterySample: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date

    // Electrical
    public let voltageV: Double?
    public let amperageA: Double?
    public let powerW: Double? // derived: voltage * amperage

    // Capacity
    public let percent: Double?
    public let currentMah: Double?
    public let maxMah: Double?
    public let designMah: Double?
    public let cycleCount: Int?

    // Thermal
    public let tempC: Double?

    // State
    public let isCharging: Bool?
    public let pluggedIn: Bool?
    public let fullyCharged: Bool?

    // Misc
    public let timeRemainingMin: Double?
    public let adapterWatts: Double?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        voltageV: Double? = nil,
        amperageA: Double? = nil,
        powerW: Double? = nil,
        percent: Double? = nil,
        currentMah: Double? = nil,
        maxMah: Double? = nil,
        designMah: Double? = nil,
        cycleCount: Int? = nil,
        tempC: Double? = nil,
        isCharging: Bool? = nil,
        pluggedIn: Bool? = nil,
        fullyCharged: Bool? = nil,
        timeRemainingMin: Double? = nil,
        adapterWatts: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.voltageV = voltageV
        self.amperageA = amperageA
        self.powerW = powerW
        self.percent = percent
        self.currentMah = currentMah
        self.maxMah = maxMah
        self.designMah = designMah
        self.cycleCount = cycleCount
        self.tempC = tempC
        self.isCharging = isCharging
        self.pluggedIn = pluggedIn
        self.fullyCharged = fullyCharged
        self.timeRemainingMin = timeRemainingMin
        self.adapterWatts = adapterWatts
    }
}
