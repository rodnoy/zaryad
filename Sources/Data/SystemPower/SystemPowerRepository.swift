import Foundation
import Domain

extension DataLayer {
    public enum SystemPower { }
}

extension DataLayer.SystemPower {
    public protocol SystemPowerRepository {
    /// Fetch a current battery power sample. Implementations should be asynchronous and return quickly.
    func fetchCurrentSample() async throws -> Domain.BatterySample
    }

    // Shell fallback implementation (parses system_profiler / ioreg).
    public final class ShellSystemPowerRepository: SystemPowerRepository {
    public init() {}

    public func fetchCurrentSample() async throws -> Domain.BatterySample {
        // Try ioreg (plist/xml) first
        func runProcess(_ launchPath: String, _ arguments: [String]) async throws -> String {
            return try await withCheckedThrowingContinuation { cont in
                let task = Process()
                task.executableURL = URL(fileURLWithPath: launchPath)
                task.arguments = arguments

                let outPipe = Pipe()
                task.standardOutput = outPipe
                task.standardError = outPipe

                do {
                    try task.run()
                } catch {
                    cont.resume(throwing: error)
                    return
                }

                task.terminationHandler = { _ in
                    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                    if let s = String(data: data, encoding: .utf8) {
                        cont.resume(returning: s)
                    } else {
                        cont.resume(throwing: NSError(domain: "ShellSystemPowerRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to read process output"]))
                    }
                }
            }
        }

        // Helpers
        func doubleFromAny(_ v: Any?) -> Double? {
            if let d = v as? Double { return d }
            if let i = v as? Int { return Double(i) }
            if let s = v as? String, let d = Double(s) { return d }
            return nil
        }

        func intFromAny(_ v: Any?) -> Int? {
            if let i = v as? Int { return i }
            if let s = v as? String, let i = Int(s) { return i }
            return nil
        }

        // Attempt 1: ioreg -rn AppleSmartBattery -a (plist/XML)
        do {
            let out = try await runProcess("/usr/sbin/ioreg", ["-rn", "AppleSmartBattery", "-a"]) // plist XML
            if let data = out.data(using: .utf8) {
                do {
                    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    // plist is usually an array of dictionaries
                    if let arr = plist as? [Any], let dict = arr.first as? [String: Any] {
                        // Common keys (may vary): Voltage, Amperage, CurrentCapacity, MaxCapacity, DesignCapacity, CycleCount, Temperature, IsCharging, ExternalConnected, FullyCharged, TimeRemaining
                        let voltageRaw = doubleFromAny(dict["Voltage"]) // often mV
                        let amperageRaw = doubleFromAny(dict["Amperage"]) // often mA (negative for discharging)
                        let currentCapacity = doubleFromAny(dict["CurrentCapacity"]) // mAh
                        let maxCapacity = doubleFromAny(dict["MaxCapacity"]) // mAh
                        let designCapacity = doubleFromAny(dict["DesignCapacity"]) // mAh
                        let cycleCount = intFromAny(dict["CycleCount"]) ?? intFromAny(dict["Cycle Count"]) // sometimes different key
                        let tempRaw = doubleFromAny(dict["Temperature"]) // deci-degrees C or C depending
                        let isCharging = (dict["IsCharging"] as? Bool) ?? (dict["Charging" ] as? Bool)
                        let externalConnected = (dict["ExternalConnected"] as? Bool) ?? (dict["ExternalConnectedState"] as? Bool)
                        let fullyCharged = (dict["FullyCharged"] as? Bool) ?? (dict["FullyChargedStatus"] as? Bool)
                        let percent = doubleFromAny(dict["CurrentPercent"]) ?? doubleFromAny(dict["Current Charge"])
                        let timeRemaining = doubleFromAny(dict["TimeRemaining"]) // minutes

                        // Convert units heuristically
                        var voltageV: Double? = nil
                        if let v = voltageRaw {
                            // if value > 100, assume mV -> V
                            voltageV = v > 1000 ? v / 1000.0 : v
                        }

                        var amperageA: Double? = nil
                        if let a = amperageRaw {
                            amperageA = abs(a) > 1000 ? a / 1000.0 : a
                        }

                        var tempC: Double? = nil
                        if let t = tempRaw {
                            // Some sensors report temperature as 300 (i.e., deci-degrees or kelvin?). Heuristic: if >100, divide by 1000 or 10 appropriately
                            if t > 1000 { tempC = t / 1000.0 }
                            else if t > 200 { tempC = t / 10.0 }
                            else { tempC = t }
                        }

                        let powerW: Double? = {
                            if let v = voltageV, let a = amperageA { return v * a }
                            return nil
                        }()

                        let sample = Domain.BatterySample(
                            timestamp: Date(),
                            voltageV: voltageV,
                            amperageA: amperageA,
                            powerW: powerW,
                            percent: percent,
                            currentMah: currentCapacity,
                            maxMah: maxCapacity,
                            designMah: designCapacity,
                            cycleCount: cycleCount,
                            tempC: tempC,
                            isCharging: isCharging,
                            pluggedIn: externalConnected,
                            fullyCharged: fullyCharged,
                            timeRemainingMin: timeRemaining,
                            adapterWatts: nil
                        )

                        return sample
                    }
                } catch {
                    // fallthrough to next method
                }
            }
        } catch {
            // ignore and try system_profiler fallback
        }

        // Attempt 2: system_profiler SPPowerDataType -json
        do {
            let out = try await runProcess("/usr/sbin/system_profiler", ["SPPowerDataType", "-json"]) // -json available on modern macOS
            if let data = out.data(using: .utf8) {
                do {
                    if let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // The structure may contain "SPPowerDataType" key mapping to array
                        if let sp = root["SPPowerDataType"] as? [[String: Any]], let first = sp.first {
                            // try to find batteries or internalBattery
                            // Keys vary; search dict recursively for keys we know
                            func find<T>(_ key: String, in dict: [String: Any]) -> T? {
                                if let v = dict[key] as? T { return v }
                                for (_, value) in dict {
                                    if let sub = value as? [String: Any], let found: T = find(key, in: sub) { return found }
                                    if let arr = value as? [[String: Any]] {
                                        for item in arr { if let found: T = find(key, in: item) { return found } }
                                    }
                                }
                                return nil
                            }

                            let voltage = find("Voltage (V)", in: first) ?? find("Voltage (V):", in: first) ?? find("voltage", in: first) as Double?
                            let amperage = find("Amperage (A)", in: first) ?? find("Amperage (A):", in: first) ?? find("amperage", in: first) as Double?
                            let percent = find("Charge Remaining (mAh)", in: first) as Double? // not ideal

                            let sample = Domain.BatterySample(
                                timestamp: Date(),
                                voltageV: voltage,
                                amperageA: amperage,
                                powerW: (voltage != nil && amperage != nil) ? (voltage! * amperage!) : nil,
                                percent: percent,
                                currentMah: nil,
                                maxMah: nil,
                                designMah: nil,
                                cycleCount: nil,
                                tempC: nil,
                                isCharging: nil,
                                pluggedIn: nil,
                                fullyCharged: nil,
                                timeRemainingMin: nil,
                                adapterWatts: nil
                            )

                            return sample
                        }
                    }
                } catch {
                    // continue to final error
                }
            }
        } catch {
            // ignore
        }

        throw NSError(domain: "ShellSystemPowerRepository", code: 10, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch power data via ioreg or system_profiler"]) 
    }
}
}
