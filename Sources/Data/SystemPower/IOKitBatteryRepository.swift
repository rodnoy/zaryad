import Domain
import Foundation
import IOKit
import os

private let logger = Logger(subsystem: "com.chargermonitor", category: "IOKitBattery")

/// Reads battery data directly from IOKit's AppleSmartBattery service.
/// Requires no sandbox (IOKit access) and no shell processes.
public final class IOKitBatteryRepository: SystemPowerRepository, @unchecked Sendable {
    public init() {}

    public func fetchCurrentSample() async throws -> BatterySample {
        // Find the AppleSmartBattery service
        let serviceName = "AppleSmartBattery"
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching(serviceName)
        )
        guard service != IO_OBJECT_NULL else {
            logger.error("AppleSmartBattery service not found")
            throw BatteryError.serviceNotFound
        }
        defer { IOObjectRelease(service) }

        // Fetch all properties as a dictionary
        var propsRef: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
        guard kr == KERN_SUCCESS, let cfDict = propsRef?.takeRetainedValue() else {
            logger.error("IORegistryEntryCreateCFProperties failed: \(kr)")
            throw BatteryError.parseError("IORegistryEntryCreateCFProperties failed with code \(kr)")
        }
        let dict = cfDict as NSDictionary as! [String: Any]

        // Extract values
        let voltageRaw = intValue(dict, "Voltage")           // mV
        let amperageRaw = intValue(dict, "Amperage")          // mA (negative = discharging)
        let currentCapacity = intValue(dict, "CurrentCapacity") // mAh
        let maxCapacity = intValue(dict, "MaxCapacity")       // mAh
        let designCapacity = intValue(dict, "DesignCapacity") // mAh
        let cycleCount = intValue(dict, "CycleCount")
        let tempRaw = intValue(dict, "Temperature")           // centi-degrees C (e.g. 3215 = 32.15°C)
        let isCharging = boolValue(dict, "IsCharging")
        let externalConnected = boolValue(dict, "ExternalConnected")
        let fullyCharged = boolValue(dict, "FullyCharged")
        let timeRemaining = intValue(dict, "TimeRemaining")   // minutes
        let adapterInfo = dict["AdapterDetails"] as? [String: Any]
        let adapterWatts = doubleValue(adapterInfo ?? [:], "Watts")
            ?? doubleValue(adapterInfo ?? [:], "AdapterWattage")

        // Unit conversions
        let voltageV: Double? = voltageRaw.map { Double($0) / 1000.0 }
        let amperageA: Double? = amperageRaw.map { Double($0) / 1000.0 }
        let tempC: Double? = tempRaw.map { Double($0) / 100.0 }

        let powerW: Double? = {
            if let v = voltageV, let a = amperageA {
                return (v * a * 100).rounded() / 100  // round to 2 decimal places
            }
            return nil
        }()

        let percent: Double? = {
            if let cur = currentCapacity, let max = maxCapacity, max > 0 {
                return (Double(cur) / Double(max)) * 100.0
            }
            return nil
        }()

        let currentMah: Double? = currentCapacity.map { Double($0) }
        let maxMah: Double? = maxCapacity.map { Double($0) }
        let designMah: Double? = designCapacity.map { Double($0) }
        let timeRemainingMin: Double? = timeRemaining.map { Double($0) }

        logger.debug(
            "Fetched sample: V=\(voltageV ?? 0, privacy: .public) A=\(amperageA ?? 0, privacy: .public) W=\(powerW ?? 0, privacy: .public) %=\(percent ?? 0, privacy: .public)"
        )

        return BatterySample(
            timestamp: Date(),
            voltageV: voltageV,
            amperageA: amperageA,
            powerW: powerW,
            percent: percent,
            currentMah: currentMah,
            maxMah: maxMah,
            designMah: designMah,
            cycleCount: cycleCount,
            tempC: tempC,
            isCharging: isCharging,
            pluggedIn: externalConnected,
            fullyCharged: fullyCharged,
            timeRemainingMin: timeRemainingMin,
            adapterWatts: adapterWatts
        )
    }

    // MARK: - Helpers

    private func intValue(_ dict: [String: Any], _ key: String) -> Int? {
        if let v = dict[key] as? Int { return v }
        if let v = dict[key] as? NSNumber { return v.intValue }
        return nil
    }

    private func doubleValue(_ dict: [String: Any], _ key: String) -> Double? {
        if let v = dict[key] as? Double { return v }
        if let v = dict[key] as? NSNumber { return v.doubleValue }
        if let v = dict[key] as? Int { return Double(v) }
        return nil
    }

    private func boolValue(_ dict: [String: Any], _ key: String) -> Bool? {
        if let v = dict[key] as? Bool { return v }
        if let v = dict[key] as? NSNumber { return v.boolValue }
        return nil
    }
}
