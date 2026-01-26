import Foundation

struct DateRange: Codable, Equatable, Sendable {
    let start: Date
    let end: Date

    static var monthToDate: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
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
        case .azure: return "cloud.fill"
        case .gcp: return "cloud.fill"
        }
    }
}
