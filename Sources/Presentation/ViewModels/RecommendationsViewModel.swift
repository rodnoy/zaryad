import Domain
import Combine
import Foundation

@MainActor
public final class RecommendationsViewModel: ObservableObject {
    @Published public private(set) var recommendations: [Recommendation] = []

    private let realtimeViewModel: RealtimeViewModel
    private let sessionsViewModel: SessionsViewModel
    private let recommendationEngine: RecommendationEngine
    private var cancellables = Set<AnyCancellable>()

    public init(
        realtimeViewModel: RealtimeViewModel,
        sessionsViewModel: SessionsViewModel,
        recommendationEngine: RecommendationEngine
    ) {
        self.realtimeViewModel = realtimeViewModel
        self.sessionsViewModel = sessionsViewModel
        self.recommendationEngine = recommendationEngine

        bind()
    }

    private func bind() {
        let realtimePublisher = Publishers.CombineLatest3(
            realtimeViewModel.$currentSample,
            realtimeViewModel.$recentSamples,
            realtimeViewModel.$healthSnapshots
        )

        Publishers.CombineLatest(realtimePublisher, sessionsViewModel.$sessions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] realtimeState, sessions in
                guard let self else { return }
                let context = RecommendationContext(
                    currentSample: realtimeState.0,
                    latestSession: sessions.first,
                    recentSamples: realtimeState.1,
                    healthSnapshots: realtimeState.2.map {
                        BatteryHealthPredictor.Observation(
                            timestamp: $0.timestamp,
                            cycleCount: $0.cycleCount,
                            healthPercent: $0.healthPercent
                        )
                    },
                    healthForecast: realtimeViewModel.healthForecast
                )
                self.recommendations = self.recommendationEngine.evaluate(context: context)
            }
            .store(in: &cancellables)
    }
}
