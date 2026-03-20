import Foundation

final class AWSProfileParser: Sendable {
    static let shared = AWSProfileParser()

    private enum AWSConfigKey: String {
        case accessKeyID = "aws_access_key_id"
        case region
        case ssoStartURL = "sso_start_url"
        case ssoSession = "sso_session"
        case sourceProfile = "source_profile"
        case roleArn = "role_arn"
        case credentialProcess = "credential_process"
    }

    func parseProfiles(in directoryURL: URL?) throws -> [AWSProfile] {
        guard let directoryURL else {
            throw CloudCostError.credentialsFileNotFound
        }

        return try withScopedDirectoryAccess(to: directoryURL) { directoryURL in
            let credentialsProfiles = try parseCredentialsFile(in: directoryURL)
            let configProfiles = try parseConfigFile(in: directoryURL)

            var profiles: [String: AWSProfile] = [:]

            for profile in credentialsProfiles {
                profiles[profile.name] = profile
            }

            for configProfile in configProfiles {
                if let existing = profiles[configProfile.name] {
                    profiles[configProfile.name] = merge(existing, with: configProfile)
                } else {
                    profiles[configProfile.name] = configProfile
                }
            }

            return Array(profiles.values)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func hasConfiguration(in directoryURL: URL?) -> Bool {
        guard let directoryURL else { return false }

        return (try? withScopedDirectoryAccess(to: directoryURL) { directoryURL in
            let credentialsURL = directoryURL.appendingPathComponent("credentials", isDirectory: false)
            let configURL = directoryURL.appendingPathComponent("config", isDirectory: false)
            return FileManager.default.fileExists(atPath: credentialsURL.path) ||
                FileManager.default.fileExists(atPath: configURL.path)
        }) ?? false
    }

    private func merge(_ existing: AWSProfile, with configProfile: AWSProfile) -> AWSProfile {
        AWSProfile(
            name: existing.name,
            accessKeyId: existing.accessKeyId ?? configProfile.accessKeyId,
            region: existing.region ?? configProfile.region,
            authenticationMethod: existing.authenticationMethod == .unknown ?
                configProfile.authenticationMethod : existing.authenticationMethod,
            isEnabled: existing.isEnabled
        )
    }

    private func parseCredentialsFile(in directoryURL: URL) throws -> [AWSProfile] {
        let credentialsURL = directoryURL.appendingPathComponent("credentials", isDirectory: false)
        guard FileManager.default.fileExists(atPath: credentialsURL.path) else {
            return []
        }

        let content = try String(contentsOf: credentialsURL, encoding: .utf8)
        return parseINIFile(content: content, isConfig: false)
    }

    private func parseConfigFile(in directoryURL: URL) throws -> [AWSProfile] {
        let configURL = directoryURL.appendingPathComponent("config", isDirectory: false)
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return []
        }

        let content = try String(contentsOf: configURL, encoding: .utf8)
        return parseINIFile(content: content, isConfig: true)
    }

    private func parseINIFile(content: String, isConfig: Bool) -> [AWSProfile] {
        var profiles: [AWSProfile] = []
        var currentProfileName: String?
        var currentValues: [String: String] = [:]

        for line in content.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix(";") {
                continue
            }

            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                if let currentProfileName {
                    profiles.append(buildProfile(name: currentProfileName, values: currentValues))
                }

                var sectionName = String(trimmedLine.dropFirst().dropLast())
                if isConfig && sectionName.hasPrefix("profile ") {
                    sectionName = String(sectionName.dropFirst("profile ".count))
                }

                currentProfileName = sectionName
                currentValues = [:]
                continue
            }

            if let equalsIndex = trimmedLine.firstIndex(of: "=") {
                let key = String(trimmedLine[..<equalsIndex])
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                let value = String(trimmedLine[trimmedLine.index(after: equalsIndex)...])
                    .trimmingCharacters(in: .whitespaces)
                currentValues[key] = value
            }
        }

        if let currentProfileName {
            profiles.append(buildProfile(name: currentProfileName, values: currentValues))
        }

        return profiles
    }

    private func buildProfile(name: String, values: [String: String]) -> AWSProfile {
        AWSProfile(
            name: name,
            accessKeyId: values[AWSConfigKey.accessKeyID.rawValue],
            region: values[AWSConfigKey.region.rawValue],
            authenticationMethod: inferAuthenticationMethod(from: values),
            isEnabled: false
        )
    }

    private func inferAuthenticationMethod(from values: [String: String]) -> AWSAuthenticationMethod {
        if values[AWSConfigKey.ssoSession.rawValue] != nil || values[AWSConfigKey.ssoStartURL.rawValue] != nil {
            return .sso
        }
        if values[AWSConfigKey.roleArn.rawValue] != nil || values[AWSConfigKey.sourceProfile.rawValue] != nil {
            return .assumeRole
        }
        if values[AWSConfigKey.credentialProcess.rawValue] != nil {
            return .externalProcess
        }
        if values[AWSConfigKey.accessKeyID.rawValue] != nil {
            return .accessKeys
        }
        return .unknown
    }

    private func withScopedDirectoryAccess<T>(
        to directoryURL: URL,
        operation: (URL) throws -> T
    ) throws -> T {
        let didStartAccessing = directoryURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                directoryURL.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(directoryURL)
    }
}
