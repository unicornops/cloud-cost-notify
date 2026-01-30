import Foundation

final class AWSProfileParser: Sendable {
    static let shared = AWSProfileParser()

    private let credentialsPath: String
    private let configPath: String

    init(credentialsPath: String? = nil, configPath: String? = nil) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        self.credentialsPath = credentialsPath ?? "\(homeDir)/.aws/credentials"
        self.configPath = configPath ?? "\(homeDir)/.aws/config"
    }

    func parseProfiles() throws -> [AWSProfile] {
        let credentialsProfiles = try parseCredentialsFile()
        let configProfiles = try parseConfigFile()

        var profiles: [String: AWSProfile] = [:]

        for profile in credentialsProfiles {
            profiles[profile.name] = profile
        }

        for configProfile in configProfiles {
            if var existing = profiles[configProfile.name] {
                if existing.region == nil && configProfile.region != nil {
                    existing = AWSProfile(
                        name: existing.name,
                        accessKeyId: existing.accessKeyId,
                        region: configProfile.region,
                        isEnabled: existing.isEnabled
                    )
                    profiles[existing.name] = existing
                }
            }
        }

        return Array(profiles.values).sorted { $0.name < $1.name }
    }

    private func parseCredentialsFile() throws -> [AWSProfile] {
        guard FileManager.default.fileExists(atPath: credentialsPath) else {
            throw CloudCostError.credentialsFileNotFound
        }

        let content = try String(contentsOfFile: credentialsPath, encoding: .utf8)
        return parseINIFile(content: content, isConfig: false)
    }

    private func parseConfigFile() throws -> [AWSProfile] {
        guard FileManager.default.fileExists(atPath: configPath) else {
            return []
        }

        let content = try String(contentsOfFile: configPath, encoding: .utf8)
        return parseINIFile(content: content, isConfig: true)
    }

    private func parseINIFile(content: String, isConfig: Bool) -> [AWSProfile] {
        var profiles: [AWSProfile] = []
        var currentProfileName: String?
        var currentAccessKeyId: String?
        var currentRegion: String?

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix(";") {
                continue
            }

            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                if let profileName = currentProfileName {
                    profiles.append(AWSProfile(
                        name: profileName,
                        accessKeyId: currentAccessKeyId,
                        region: currentRegion,
                        isEnabled: false
                    ))
                }

                var sectionName = String(trimmedLine.dropFirst().dropLast())

                if isConfig && sectionName.hasPrefix("profile ") {
                    sectionName = String(sectionName.dropFirst("profile ".count))
                }

                currentProfileName = sectionName
                currentAccessKeyId = nil
                currentRegion = nil
                continue
            }

            if let equalsIndex = trimmedLine.firstIndex(of: "=") {
                let key = String(trimmedLine[..<equalsIndex])
                    .trimmingCharacters(in: .whitespaces).lowercased()
                let value = String(trimmedLine[trimmedLine.index(after: equalsIndex)...])
                    .trimmingCharacters(in: .whitespaces)

                switch key {
                case "aws_access_key_id":
                    currentAccessKeyId = value
                case "region":
                    currentRegion = value
                default:
                    break
                }
            }
        }

        if let profileName = currentProfileName {
            profiles.append(AWSProfile(
                name: profileName,
                accessKeyId: currentAccessKeyId,
                region: currentRegion,
                isEnabled: false
            ))
        }

        return profiles
    }

    func hasCredentialsFile() -> Bool {
        FileManager.default.fileExists(atPath: credentialsPath)
    }
}
