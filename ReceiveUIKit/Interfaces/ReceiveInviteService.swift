import Dependencies
import DependenciesMacros
import WiseCore

@DependencyClient
public struct ReceiveInviteService {
    public var fetchInviteAvailability: (_ profileId: ProfileId?) async -> Bool = { _ in true }
}

extension ReceiveInviteService: TestDependencyKey {
    public static let testValue = ReceiveInviteService()
}

extension DependencyValues {
    var receiveInviteService: ReceiveInviteService {
        get { self[ReceiveInviteService.self] }
        set { self[ReceiveInviteService.self] = newValue }
    }
}
