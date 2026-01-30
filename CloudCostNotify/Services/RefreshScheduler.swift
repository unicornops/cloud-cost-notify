import Foundation
import Combine

@MainActor
@Observable
final class RefreshScheduler {
    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case fifteenMinutes = 15
        case thirtyMinutes = 30
        case oneHour = 60
        case twoHours = 120
        case fourHours = 240
        case eightHours = 480

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .oneHour: return "1 hour"
            case .twoHours: return "2 hours"
            case .fourHours: return "4 hours"
            case .eightHours: return "8 hours"
            }
        }

        var timeInterval: TimeInterval {
            TimeInterval(rawValue * 60)
        }
    }

    private(set) var interval: RefreshInterval = .oneHour
    private(set) var lastRefresh: Date?
    private(set) var nextRefresh: Date?
    private(set) var isScheduled: Bool = false

    private var timer: Timer?
    private var refreshAction: (() async -> Void)?

    func setInterval(_ interval: RefreshInterval) {
        self.interval = interval
        if isScheduled {
            stop()
            start()
        }
    }

    func setRefreshAction(_ action: @escaping () async -> Void) {
        self.refreshAction = action
    }

    func start() {
        guard !isScheduled else { return }

        isScheduled = true
        scheduleNextRefresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isScheduled = false
        nextRefresh = nil
    }

    func refreshNow() {
        lastRefresh = Date()
        Task {
            await refreshAction?()
        }
        if isScheduled {
            scheduleNextRefresh()
        }
    }

    private func scheduleNextRefresh() {
        timer?.invalidate()

        let next = Date().addingTimeInterval(interval.timeInterval)
        nextRefresh = next

        timer = Timer.scheduledTimer(withTimeInterval: interval.timeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.lastRefresh = Date()
                await self?.refreshAction?()
                self?.nextRefresh = Date().addingTimeInterval(self?.interval.timeInterval ?? 3600)
            }
        }
    }

    var timeUntilNextRefresh: TimeInterval? {
        guard let next = nextRefresh else { return nil }
        return max(0, next.timeIntervalSinceNow)
    }

    var formattedTimeUntilNextRefresh: String? {
        guard let seconds = timeUntilNextRefresh else { return nil }

        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "Less than a minute"
        } else if minutes == 1 {
            return "1 minute"
        } else if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return hours == 1 ? "1 hour" : "\(hours) hours"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}
