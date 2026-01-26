import Foundation

enum CloudCostError: Error, LocalizedError {
    case notConfigured
    case authenticationFailed(String)
    case networkError(Error)
    case apiError(String)
    case parseError(String)
    case noAccountsEnabled
    case profileNotFound(String)
    case credentialsFileNotFound
    case invalidCredentialsFormat
    case rateLimitExceeded
    case insufficientPermissions(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloud provider is not configured"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .noAccountsEnabled:
            return "No accounts are enabled for cost fetching"
        case .profileNotFound(let profile):
            return "AWS profile '\(profile)' not found"
        case .credentialsFileNotFound:
            return "AWS credentials file not found at ~/.aws/credentials"
        case .invalidCredentialsFormat:
            return "Invalid AWS credentials file format"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .insufficientPermissions(let message):
            return "Insufficient permissions: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Configure your cloud provider credentials in Settings."
        case .authenticationFailed:
            return "Check your credentials and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .apiError:
            return "Try again later or check the service status."
        case .parseError:
            return "This may be a temporary issue. Try again later."
        case .noAccountsEnabled:
            return "Enable at least one account in Settings."
        case .profileNotFound:
            return "Check your ~/.aws/credentials file for available profiles."
        case .credentialsFileNotFound:
            return "Create an AWS credentials file at ~/.aws/credentials"
        case .invalidCredentialsFormat:
            return "Ensure your credentials file follows the standard INI format."
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again."
        case .insufficientPermissions:
            return "Ensure your IAM user/role has ce:GetCostAndUsage permission."
        }
    }
}
