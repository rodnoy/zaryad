import Foundation

public protocol StartSessionUseCase {
    func start() async throws -> Session
}

public protocol AppendSampleToSessionUseCase {
    func append(sample: BatterySample) async throws
}

public protocol StopSessionUseCase {
    func stop() async throws -> Session
}

public protocol GetSessionsUseCase {
    func fetchAll() async throws -> [Session]
}
