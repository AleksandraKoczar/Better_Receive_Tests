import AnalyticsKit
import Foundation

public typealias ManagePaymentRequestFlowAnalyticsTracker = AnalyticsFlowTrackerImpl<ManagePaymentRequestFlowAnalytics>

public struct ManagePaymentRequestFlowAnalytics: AnalyticsFlow {
    public static let identity = AnalyticsIdentity(name: "Manage Requests")
}
