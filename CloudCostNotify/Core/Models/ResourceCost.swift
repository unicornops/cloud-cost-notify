import Foundation

struct ResourceCost: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let serviceName: String
    let cost: Decimal
    let currency: String
    let usageQuantity: Double?
    let usageUnit: String?

    init(id: String = UUID().uuidString, serviceName: String, cost: Decimal, currency: String = "USD", usageQuantity: Double? = nil, usageUnit: String? = nil) {
        self.id = id
        self.serviceName = serviceName
        self.cost = cost
        self.currency = currency
        self.usageQuantity = usageQuantity
        self.usageUnit = usageUnit
    }

    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }

    var formattedUsage: String? {
        guard let quantity = usageQuantity, let unit = usageUnit else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        guard let formattedQuantity = formatter.string(from: NSNumber(value: quantity)) else { return nil }
        return "\(formattedQuantity) \(unit)"
    }
}
