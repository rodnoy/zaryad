import Foundation
import SwiftData

/// SwiftData model for persisting charging sessions.
@Model
public final class SDSession {
    @Attribute(.unique) public var sessionID: UUID
    public var name: String?
    public var startTimestamp: Date
    public var endTimestamp: Date?
    /// Encoded [BatterySample] as JSON data
    public var samplesData: Data

    public init(
        sessionID: UUID = UUID(),
        name: String? = nil,
        startTimestamp: Date = Date(),
        endTimestamp: Date? = nil,
        samplesData: Data = Data()
    ) {
        self.sessionID = sessionID
        self.name = name
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.samplesData = samplesData
    }

    /// Create from a Domain Session.
    public convenience init(from session: Session) {
        let encoded = (try? JSONEncoder().encode(session.samples)) ?? Data()
        self.init(
            sessionID: session.id,
            name: session.name,
            startTimestamp: session.startTimestamp,
            endTimestamp: session.endTimestamp,
            samplesData: encoded
        )
    }

    /// Convert back to a Domain Session.
    public func toDomain() -> Session {
        let samples: [BatterySample] = (try? JSONDecoder().decode([BatterySample].self, from: samplesData)) ?? []
        return Session(
            id: sessionID,
            name: name,
            start: startTimestamp,
            end: endTimestamp,
            samples: samples
        )
    }
}
