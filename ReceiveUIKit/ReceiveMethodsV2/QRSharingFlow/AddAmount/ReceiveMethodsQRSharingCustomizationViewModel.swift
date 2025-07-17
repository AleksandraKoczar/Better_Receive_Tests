import Neptune
import ReceiveKit
import SwiftUICore
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol ReceiveMethodsQRSharingCustomizationDelegate: AnyObject {
    func customize(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        result: ReceiveMethodsQRSharingCustomizationResult
    )
}

struct ReceiveMethodsQRSharingCustomizationContent: Equatable {}

enum ReceiveMethodsQRSharingCustomizationResult {
    case cancelled
    case customized(ReceiveMethodsQRSharingMode.SingleSharingModel)
}

// sourcery: AutoMockable
final class ReceiveMethodsQRSharingCustomizationViewModel:
    ModelStateViewModel<ReceiveMethodsQRSharingCustomizationContent, Void, Error> {
    @Published
    var message: String?

    private let accountDetailsId: AccountDetailsId
    private let profileId: ProfileId
    private let alias: ReceiveMethodAlias

    @Published
    private var moneyInput = MoneyInputValue(raw: "")
    private weak var delegate: ReceiveMethodsQRSharingCustomizationDelegate?

    init(
        alias: ReceiveMethodAlias,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        delegate: ReceiveMethodsQRSharingCustomizationDelegate
    ) {
        self.alias = alias
        self.accountDetailsId = accountDetailsId
        self.profileId = profileId
        super.init()
        self.delegate = delegate

        state = .content(.init(), error: nil)
    }
}

extension ReceiveMethodsQRSharingCustomizationViewModel {
    func configureView() {
        state = .content(.init(), error: nil)
    }

    func moneyInputValue() -> Binding<MoneyInputValue> {
        .init {
            self.moneyInput
        } set: { newValue in
            self.moneyInput.raw = newValue.raw
        }
    }

    func createTapped() {
        let amount = MoneyFormatter.number(moneyInput.raw)?.decimalValue
        delegate?.customize(
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            result: .customized(
                ReceiveMethodsQRSharingMode.SingleSharingModel(
                    alias: alias,
                    amount: amount,
                    message: message
                )
            )
        )
    }
}
