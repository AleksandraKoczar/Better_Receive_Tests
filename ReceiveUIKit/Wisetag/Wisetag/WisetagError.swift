import Foundation

// sourcery: CaseNameAnalyticsIdentifyable
enum WisetagError: LocalizedError {
    case ineligible
    case loadingError(error: Error)
    case updateSharableLinkError(error: Error)
    case downloadWisetagImageError
}
