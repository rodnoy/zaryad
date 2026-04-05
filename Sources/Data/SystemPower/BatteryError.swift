import Domain
import Foundation

public enum BatteryError: LocalizedError, Sendable {
    case serviceNotFound
    case propertyNotFound(String)
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return "AppleSmartBattery service not found — is this a MacBook with a battery?"
        case .propertyNotFound(let key):
            return "Battery property '\(key)' not found in IORegistry"
        case .parseError(let detail):
            return "Failed to parse battery data: \(detail)"
        }
    }
}
