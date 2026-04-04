import Foundation

public protocol SystemPowerRepository: Sendable {
    func fetchCurrentSample() async throws -> BatterySample
}
