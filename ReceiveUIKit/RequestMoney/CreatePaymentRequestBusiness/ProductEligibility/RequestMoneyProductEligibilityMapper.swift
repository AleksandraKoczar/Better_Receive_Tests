import Foundation
import ReceiveKit

enum RequestMoneyProductEligibilityMapper {
    static func make(from requestTypes: [PaymentRequestEligibleRequestType]) -> RequestMoneyProductEligibility {
        let requestTypeSet = Set<PaymentRequestEligibleRequestType>(requestTypes)
        let containsSingleUse = requestTypeSet.contains(.singleUse)
        let containsReusable = requestTypeSet.contains(.reusable)
        switch (containsSingleUse, containsReusable) {
        case (true, true):
            return .singleUseAndReusable
        case (true, false):
            return .singleUse
        case (false, true):
            return .reusable
        case (false, false):
            return .ineligible
        }
    }
}
