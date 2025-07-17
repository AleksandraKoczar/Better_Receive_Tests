import Neptune
import ReceiveKit
import TransferResources

// sourcery: AutoMockable
protocol RequestMoneyPayWithWiseEducationPresenter: AnyObject {
    func start(with view: RequestMoneyPayWithWiseEducationView)
}

final class RequestMoneyPayWithWiseEducationPresenterImpl {
    private weak var routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate?

    init(
        routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate
    ) {
        self.routingDelegate = routingDelegate
    }
}

// MARK: - Helpers

private extension RequestMoneyPayWithWiseEducationPresenterImpl {
    func makeViewModel() -> RequestMoneyPayWithWiseEducationViewModel {
        let description = RequestMoneyPayWithWiseEducationViewModel.MarkupLabel(
            text: L10n.RequestMoney.PayWithWiseEducation.description,
            action: { [weak self] in
                self?.routingDelegate?.showInviteFriends()
            }
        )
        return RequestMoneyPayWithWiseEducationViewModel(
            image: Illustrations.megaphone.image,
            title: L10n.RequestMoney.PayWithWiseEducation.title,
            subtitle: L10n.RequestMoney.PayWithWiseEducation.subtitle,
            description: description,
            action: Action(
                title: L10n.RequestMoney.PayWithWiseEducation.PrimaryButton.title,
                handler: { [weak self] in
                    self?.routingDelegate?.dismiss()
                }
            )
        )
    }
}

// MARK: - RequestMoneyPayWithWiseEducationPresenter

extension RequestMoneyPayWithWiseEducationPresenterImpl: RequestMoneyPayWithWiseEducationPresenter {
    func start(with view: RequestMoneyPayWithWiseEducationView) {
        let viewModel = makeViewModel()
        view.configure(with: viewModel)
    }
}
