import Foundation

struct DateRange: Codable, Equatable, Sendable {
    let start: Date
    let end: Date

    static var monthToDate: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components) ?? now
        return DateRange(start: startOfMonth, end: now)
    }

    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct CostData: Codable, Equatable, Sendable {
    let provider: CloudProviderType
    let period: DateRange
    let totalCost: Decimal
    let currency: String
    let accountCosts: [AccountCost]
    let lastUpdated: Date

    var formattedTotalCost: String {
        formatCurrency(totalCost)
    }

    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    var aggregatedResourceCosts: [ResourceCost] {
        var serviceTotals: [String: Decimal] = [:]

        for accountCost in accountCosts {
            for resourceCost in accountCost.resourceCosts {
                serviceTotals[resourceCost.serviceName, default: .zero] += resourceCost.cost
            }
        }

        return serviceTotals
            .map { serviceName, cost in
                ResourceCost(
                    id: "\(provider.rawValue)_\(serviceName)",
                    serviceName: serviceName,
                    cost: cost,
                    currency: currency
                )
            }
            .sorted { $0.cost > $1.cost }
    }
}

struct AccountCost: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let accountId: String
    let accountName: String
    let totalCost: Decimal
    let currency: String
    let resourceCosts: [ResourceCost]

    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: totalCost as NSDecimalNumber) ?? "$0.00"
    }
}

enum CloudProviderType: String, Codable, CaseIterable, Identifiable, Sendable {
    case aws = "AWS"
    case azure = "Azure"
    case gcp = "GCP"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aws: return "Amazon Web Services"
        case .azure: return "Microsoft Azure"
        case .gcp: return "Google Cloud Platform"
        }
    }

    var iconName: String {
        switch self {
        case .aws: return "cloud.fill"
        case .azure: return "building.2.crop.circle"
        case .gcp: return "globe.americas.fill"
        }
    }

    var scopeSingularTitle: String {
        switch self {
        case .aws:
            return "Account"
        case .azure:
            return "Subscription"
        case .gcp:
            return "Project"
        }
    }

    var scopePluralTitle: String {
        switch self {
        case .aws:
            return "Accounts"
        case .azure:
            return "Subscriptions"
        case .gcp:
            return "Projects"
        }
    }

    var supportsCostFetching: Bool {
        switch self {
        case .aws:
            return true
        case .azure, .gcp:
            return false
        }
    }
}
