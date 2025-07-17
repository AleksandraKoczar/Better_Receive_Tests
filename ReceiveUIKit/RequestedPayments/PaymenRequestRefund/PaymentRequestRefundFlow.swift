import ApiKit
import BalanceKit
import DeepLinkKit
import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

@MainActor
final class PaymentRequestRefundFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let paymentId: String
    private let profileId: ProfileId
    private let navigationController: UINavigationController
    private let presenterFactory: ViewControllerPresenterFactory
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let flowPresenter: FlowPresenter

    private var createRefundDismisser: ViewControllerDismisser?
    private var reviewDismisser: ViewControllerDismisser?
    private var successDismisser: ViewControllerDismisser?
    private var failureDismisser: ViewControllerDismisser?

    private var topUpFlow: (any Flow<Void>)?

    init(
        paymentId: String,
        profileId: ProfileId,
        navigationController: UINavigationController,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        allDeepLinksUIFactory: AllDeepLinksUIFactory,
        flowPresenter: FlowPresenter
    ) {
        self.paymentId = paymentId
        self.profileId = profileId
        self.navigationController = navigationController
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        presenterFactory = viewControllerPresenterFactory
        self.flowPresenter = flowPresenter
    }

    func start() {
        let viewModel = CreateRefundViewModel(
            paymentId: paymentId,
            profileId: profileId,
            delegate: self
        )

        createRefundDismisser = presenterFactory
            .makePushPresenter(navigationController: navigationController)
            .present(
                view: {
                    CreateRefundView(viewModel: viewModel)
                },
                completion: { [weak self] in
                    self?.flowHandler.flowStarted()
                }
            )
    }

    func terminate() {
        createRefundDismisser?.dismiss(animated: false)
    }
}

extension PaymentRequestRefundFlow: CreateRefundDelegate {
    func refundInitiated(_ refund: Refund) {
        let viewModel = ReviewRefundViewModel(
            paymentId: paymentId,
            refund: refund,
            profileId: profileId,
            delegate: self
        )

        reviewDismisser = presenterFactory
            .makePushPresenter(navigationController: navigationController)
            .present(
                view: {
                    ReviewRefundView(viewModel: viewModel)
                }
            )
    }

    func topUp(balanceId: BalanceId, completion: @escaping () -> Void) {
        let topUpDeepLink = DeepLinkTopUpBalanceRouteImpl(balanceIdentifier: balanceId.value)
        guard let flow = allDeepLinksUIFactory.build(
            for: topUpDeepLink,
            hostController: navigationController,
            with: .init(source: "Payment request refund")
        ) else {
            LogInfo("Top up flow for balance \(balanceId.value) not found")
            return
        }

        flow.onFinish { [weak self] _, dismisser in
            self?.topUpFlow = nil
            dismisser.dismiss { completion() }
        }

        topUpFlow = flow
        flowPresenter.start(flow: flow)
    }
}

extension PaymentRequestRefundFlow: ReviewRefundDelegate {
    func dismiss() {
        reviewDismisser?.dismiss()
    }

    func showSuccess(refund: Refund) {
        let message: String = {
            guard let name = refund.payerData?.name else {
                return L10n.PaymentRequest.Refund.Success.noNameMessage(MoneyFormatter.format(refund.amount))
            }
            return L10n.PaymentRequest.Refund.Success.message(MoneyFormatter.format(refund.amount), name)
        }()
        let prompt = PromptViewControllerFactory.makeSuccess(
            title: L10n.PaymentRequest.Refund.Success.title,
            message: message,
            primaryButton: .init(title: L10n.PaymentRequest.Refund.Success.button, actionHandler: { [weak self] _ in
                self?.flowHandler.flowFinished(result: (), dismisser: self?.createRefundDismisser)
            })
        )

        successDismisser = presenterFactory
            .makePushPresenter(navigationController: navigationController)
            .present(viewController: prompt)
    }

    func showFailure() {
        navigationController.hideHud()

        let prompt = PromptViewControllerFactory.makeFailure(
            title: L10n.PaymentRequest.Refund.Failure.title,
            message: L10n.PaymentRequest.Refund.Failure.message,
            primaryButton: .init(title: L10n.PaymentRequest.Refund.Failure.button, actionHandler: { [weak self] _ in
                guard let self else { return }
                failureDismisser.dismiss {}
            })
        )

        failureDismisser = presenterFactory
            .makePushPresenter(navigationController: navigationController)
            .present(viewController: prompt)
    }

    func showLoader() {
        navigationController.showHud()
    }
}
