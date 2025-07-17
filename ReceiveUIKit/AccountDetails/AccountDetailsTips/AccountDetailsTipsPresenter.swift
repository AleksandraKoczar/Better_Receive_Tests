import AnalyticsKit
import Combine
import CombineSchedulers
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
@preconcurrency import TWUI
import WiseCore

// sourcery: AutoMockable
@MainActor
protocol AccountDetailsTipsPresenter: AnyObject {
    func start(with view: AccountDetailsTipsView) async
    func closeButtonTapped()
}

final class AccountDetailsTipsPresenterImpl {
    private let profileId: ProfileId
    private let accountDetailsId: AccountDetailsId
    private let flowTracker: AnalyticsFlowTrackerImpl<AccountDetailsTipsFlowAnalytics>
    private let accountDetailsTipsUseCase: AccountDetailsTipsUseCase
    private let router: AccountDetailsTipsRouter

    private weak var view: AccountDetailsTipsView?

    init(
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        flowTracker: AnalyticsFlowTrackerImpl<AccountDetailsTipsFlowAnalytics>,
        router: AccountDetailsTipsRouter,
        accountDetailsTipsUseCase: AccountDetailsTipsUseCase = AccountDetailsTipsUseCaseFactory.make()
    ) {
        self.profileId = profileId
        self.accountDetailsId = accountDetailsId
        self.flowTracker = flowTracker
        self.accountDetailsTipsUseCase = accountDetailsTipsUseCase
        self.router = router
    }
}

// MARK: - AccountDetailsTipsPresenter

extension AccountDetailsTipsPresenterImpl: AccountDetailsTipsPresenter {
    @MainActor
    func start(with view: AccountDetailsTipsView) async {
        flowTracker.track(AccountDetailsTipsFlowAnalytics.Opened())
        self.view = view
        view.showHud()
        do {
            async let accountDetailsTips = accountDetailsTipsUseCase.accountDetailsTips(
                profileId: profileId,
                accountDetailsId: accountDetailsId
            )

            let viewModel = try await makeViewModel(from: accountDetailsTips)
            view.hideHud()
            view.configure(with: viewModel)
        } catch {
            view.hideHud()

            view.showErrorAlert(
                title: L10n.Generic.Error.title,
                message: error.localizedDescription
            )
        }
    }

    func closeButtonTapped() {
        router.dismiss()
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(from accountDetailsTips: AccountDetailsTips) -> UpsellViewModel {
        UpsellViewModel(
            headerModel: .init(title: accountDetailsTips.title),
            imageView: IllustrationView(asset: .image(Illustrations.globe.image)),
            leadingView: accountDetailsTips.alert.map { alert in
                StackInlineAlertView().with {
                    $0.setStyle(makeStyle(from: alert.type))
                    $0.configure(with: .init(message: alert.message))
                }
            },
            items: accountDetailsTips.summaries.map { summary in
                .init(
                    title: summary.title,
                    description: summary.description,
                    icon: makeIconImage(from: summary.icon)
                )
            },
            linkAction: accountDetailsTips.help.map { help in
                .init(title: help.label, handler: { [weak self] in
                    self?.showHelpLink(href: help.href)
                })
            },
            footerModel: .init(
                primaryAction: .init(
                    title: accountDetailsTips.ctaLabel,
                    handler: { [weak self] in
                        self?.closeButtonTapped()
                    }
                )
            )
        )
    }

    private func makeStyle(from type: AccountDetailsTips.AlertType) -> InlineAlertStyle {
        switch type {
        case .positive:
            .positive
        case .neutral:
            .neutral
        case .warning:
            .warning
        case .negative:
            .negative
        }
    }

    private func makeIconImage(from icon: AccountDetailsTips.SummaryItemIcon) -> UIImage {
        switch icon {
        case .money:
            Icons.money.image
        case .globe:
            Icons.globe.image
        case .house:
            Icons.house.image
        }
    }

    private func showHelpLink(href: String) {
        flowTracker.track(AccountDetailsTipsFlowAnalytics.HelpLinkClicked())
        let url = Branding.current.url.appendingPathComponent(href)
        router.open(url: url)
    }
}
