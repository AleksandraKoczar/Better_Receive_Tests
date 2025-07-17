import Foundation
import UserKit

struct LoadAccountDetailsStatusInfo {
    enum Status {
        case active
        case inactive
    }

    let profile: Profile
    let status: Status
}

enum LoadAccountDetailsStatusRouterAction {
    case dismissed
    case loaded(LoadAccountDetailsStatusInfo)
}

protocol LoadAccountDetailsStatusRouter {
    func route(action: LoadAccountDetailsStatusRouterAction)
}
