import BalanceKit
import UserKit

enum LoadAccountDetailsEligibilityResult {
    struct Info {
        let profile: Profile
        let requirements: [AccountDetailsRequirement]
    }

    case eligible(Info)
    case ineligible(Profile)
}

enum LoadAccountDetailsEligibilityRouterAction {
    case dismissed
    case loaded(LoadAccountDetailsEligibilityResult)
}

protocol LoadAccountDetailsEligibilityRouter {
    func route(action: LoadAccountDetailsEligibilityRouterAction)
}
