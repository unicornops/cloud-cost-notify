import Foundation

struct CloudAccount: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let provider: CloudProviderType
    let name: String
    let accountIdentifier: String?
    let profileName: String?
    var isEnabled: Bool

    init(
        id: String,
        provider: CloudProviderType,
        name: String,
        accountIdentifier: String? = nil,
        profileName: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.provider = provider
        self.name = name
        self.accountIdentifier = accountIdentifier
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
    let authenticationMethod: AWSAuthenticationMethod
    var isEnabled: Bool

    var id: String { name }

    init(
        name: String,
        accessKeyId: String? = nil,
        region: String? = nil,
        authenticationMethod: AWSAuthenticationMethod = .unknown,
        isEnabled: Bool = false
    ) {
        self.name = name
        self.accessKeyId = accessKeyId
        self.region = region
        self.authenticationMethod = authenticationMethod
        self.isEnabled = isEnabled
    }

    var credentialSummary: String {
        authenticationMethod.displayName
    }

    var detailSummary: String {
        var components: [String] = [authenticationMethod.displayName]
        if let region, !region.isEmpty {
            components.append(region)
        }
        return components.joined(separator: " • ")
    }
}

enum AWSAuthenticationMethod: String, Codable, CaseIterable, Hashable, Sendable {
    case accessKeys
    case sso
    case assumeRole
    case externalProcess
    case unknown

    var displayName: String {
        switch self {
        case .accessKeys:
            return "Access keys"
        case .sso:
            return "AWS SSO"
        case .assumeRole:
            return "Assume role"
        case .externalProcess:
            return "Credential process"
        case .unknown:
            return "Profile"
        }
    }
}
