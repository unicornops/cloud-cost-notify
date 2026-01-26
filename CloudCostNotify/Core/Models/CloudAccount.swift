import Foundation

struct CloudAccount: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let provider: CloudProviderType
    let name: String
    let profileName: String?
    var isEnabled: Bool

    init(id: String, provider: CloudProviderType, name: String, profileName: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.provider = provider
        self.name = name
        self.profileName = profileName
        self.isEnabled = isEnabled
    }

    var displayName: String {
        if let profile = profileName {
            return "\(name) (\(profile))"
        }
        return name
    }
}

struct AWSProfile: Identifiable, Codable, Equatable, Hashable, Sendable {
    let name: String
    let accessKeyId: String?
    let region: String?
    var isEnabled: Bool

    var id: String { name }

    init(name: String, accessKeyId: String? = nil, region: String? = nil, isEnabled: Bool = false) {
        self.name = name
        self.accessKeyId = accessKeyId
        self.region = region
        self.isEnabled = isEnabled
    }
}
