import Foundation
import AWSCostExplorer
import AWSClientRuntime
import AWSSDKIdentity

actor AWSCostExplorerClient {
    private var clientCache: [String: CostExplorerClient] = [:]

    func getClient(
        for profileName: String,
        region: String = "us-east-1",
        sharedConfigDirectory: URL?
    ) async throws -> CostExplorerClient {
        let cacheKey = "\(profileName)_\(region)_\(sharedConfigDirectory?.path ?? "default")"

        if let cachedClient = clientCache[cacheKey] {
            return cachedClient
        }

        let credentialIdentityResolver = ProfileAWSCredentialIdentityResolver(
            profileName: profileName
        )

        let config = try await CostExplorerClient.Config(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: region
        )

        let client = CostExplorerClient(config: config)
        clientCache[cacheKey] = client

        return client
    }

    func fetchCosts(
        profileName: String,
        startDate: Date,
        endDate: Date,
        sharedConfigDirectory: URL?,
        region: String = "us-east-1"
    ) async throws -> GetCostAndUsageOutput {
        let didStartAccessing = sharedConfigDirectory?.startAccessingSecurityScopedResource() ?? false
        defer {
            if didStartAccessing {
                sharedConfigDirectory?.stopAccessingSecurityScopedResource()
            }
        }

        configureAWSSharedFiles(using: sharedConfigDirectory)

        let client = try await getClient(
            for: profileName,
            region: region,
            sharedConfigDirectory: sharedConfigDirectory
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)

        let timePeriod = CostExplorerClientTypes.DateInterval(
            end: endString,
            start: startString
        )

        let groupByService = CostExplorerClientTypes.GroupDefinition(
            key: "SERVICE",
            type: .dimension
        )

        let groupByAccount = CostExplorerClientTypes.GroupDefinition(
            key: "LINKED_ACCOUNT",
            type: .dimension
        )

        let input = GetCostAndUsageInput(
            granularity: .monthly,
            groupBy: [groupByService, groupByAccount],
            metrics: ["UnblendedCost"],
            timePeriod: timePeriod
        )

        do {
            return try await client.getCostAndUsage(input: input)
        } catch {
            if let awsError = error as? AWSServiceError {
                throw CloudCostError.apiError(awsError.message ?? "Unknown AWS error")
            }
            throw CloudCostError.networkError(error)
        }
    }

    func clearCache() {
        clientCache.removeAll()
    }

    private func configureAWSSharedFiles(using directoryURL: URL?) {
        guard let directoryURL else {
            unsetenv("AWS_SHARED_CREDENTIALS_FILE")
            unsetenv("AWS_CONFIG_FILE")
            return
        }

        let credentialsPath = directoryURL.appendingPathComponent("credentials", isDirectory: false).path
        let configPath = directoryURL.appendingPathComponent("config", isDirectory: false).path

        if FileManager.default.fileExists(atPath: credentialsPath) {
            setenv("AWS_SHARED_CREDENTIALS_FILE", credentialsPath, 1)
        } else {
            unsetenv("AWS_SHARED_CREDENTIALS_FILE")
        }
        if FileManager.default.fileExists(atPath: configPath) {
            setenv("AWS_CONFIG_FILE", configPath, 1)
        } else {
            unsetenv("AWS_CONFIG_FILE")
        }
    }
}
