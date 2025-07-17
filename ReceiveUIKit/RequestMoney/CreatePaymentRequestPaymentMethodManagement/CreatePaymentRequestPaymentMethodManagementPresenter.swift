import Foundation
import Neptune
import ReceiveKit
import TransferResources
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestPaymentMethodManagementPresenter: AnyObject {
    func start(with view: CreatePaymentRequestPaymentMethodManagementView)
    func footerButtonTapped()
    func secondaryFooterButtonTapped()
}

final class CreatePaymentRequestPaymentMethodManagementPresenterImpl {
    private weak var view: CreatePaymentRequestPaymentMethodManagementView?
    private weak var routingDelegate: CreatePaymentRequestRoutingDelegate?
    private weak var delegate: PaymentMethodsDelegate?

    private let onSave: ([PaymentRequestV2PaymentMethods]) -> Void
    private let localPreferences: [PaymentRequestV2PaymentMethods]
    private let paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability

    private var selectedPaymentMethods: [PaymentRequestV2PaymentMethods: Bool] = [:]

    init(
        delegate: PaymentMethodsDelegate?,
        routingDelegate: CreatePaymentRequestRoutingDelegate?,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onSave: @escaping (([PaymentRequestV2PaymentMethods]) -> Void)
    ) {
        self.delegate = delegate
        self.routingDelegate = routingDelegate
        self.localPreferences = localPreferences
        self.paymentMethodsAvailability = paymentMethodsAvailability
        self.onSave = onSave
    }
}

extension CreatePaymentRequestPaymentMethodManagementPresenterImpl: CreatePaymentRequestPaymentMethodManagementPresenter {
    func start(with view: CreatePaymentRequestPaymentMethodManagementView) {
        self.view = view
        localPreferences.forEach { selectedPaymentMethods[$0] = true }
        let viewModel = makeViewModel()
        view.configure(with: viewModel)
    }

    func footerButtonTapped() {
        let selectedMethods = Array(selectedPaymentMethods.filter { $0.value }.keys)
        onSave(selectedMethods)
    }

    func secondaryFooterButtonTapped() {
        routingDelegate?.showPaymentMethodManagementOnWeb(delegate: delegate)
    }
}

private extension CreatePaymentRequestPaymentMethodManagementPresenterImpl {
    func makeViewModel() -> CreatePaymentRequestMethodManagementViewModel {
        CreatePaymentRequestMethodManagementViewModel(
            title: L10n.PaymentRequest.Create.PaymentMethodsManagement.title,
            subtitle: L10n.PaymentRequest.Create.PaymentMethodsManagement.subtitle,
            options: makeOptionViewModels(),
            footerAction: Action(
                title: L10n.PaymentRequest.Create.PaymentMethodsManagement.primaryAction,
                handler: { [weak self] in
                    self?.footerButtonTapped()
                }
            ),
            secondaryFooterAction: Action(
                title: L10n.PaymentRequest.Create.PaymentMethodsManagement.secondaryAction,
                handler: { [weak self] in
                    self?.secondaryFooterButtonTapped()
                }
            )
        )
    }

    func makeLeadingViewModel(from urnString: String) -> LeadingViewModel {
        if let urn = try? URN(urnString) {
            if let image = IconFactory.icon(urn: urn) {
                return LeadingViewModel.avatar(.icon(image))
            } else if IconFactory.isApplePayURN(urn) {
                return LeadingViewModel.icon(WiseAtomsAssets.Assets.applePay.image)
            }
        }
        return LeadingViewModel.avatar(.icon(Icons.fastFlag.image))
    }

    func makeAvailableOptionViewModel(
        paymentMethod: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod
    ) -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let paymentMethodType = paymentMethod.type
        let switchOptionViewModel = CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel(
            title: paymentMethod.name,
            subtitle: paymentMethod.summary,
            leadingViewModel: makeLeadingViewModel(from: paymentMethod.urn),
            isOn: selectedPaymentMethods[paymentMethodType] ?? false,
            isEnabled: true,
            onToggle: { [weak self] isSelected in
                guard let self else {
                    return
                }
                selectedPaymentMethods[paymentMethodType] = isSelected
            }
        )
        return .switchOptionViewModel(switchOptionViewModel)
    }

    func makeUnavailableOptionViewModel(
        paymentMethod: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod
    ) -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let switchOptionViewModel = CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel(
            title: paymentMethod.name,
            subtitle: paymentMethod.summary,
            leadingViewModel: makeLeadingViewModel(from: paymentMethod.urn),
            isOn: false,
            isEnabled: false,
            onToggle: { _ in }
        )
        return .switchOptionViewModel(switchOptionViewModel)
    }

    func makePayWithWiseViewModel(
        paymentMethod: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod
    ) -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let optionViewModel = OptionViewModel(
            title: paymentMethod.name,
            subtitle: paymentMethod.summary,
            leadingView: makeLeadingViewModel(from: paymentMethod.urn),
            isEnabled: paymentMethod.available
        )
        return .payWithWiseOptionViewModel(optionViewModel)
    }

    private func makeRequiresUserActionOptionViewModel(
        paymentMethod: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod,
        forms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm]
    ) -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let viewModel = CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel(
            title: paymentMethod.name,
            subtitle: paymentMethod.summary,
            leadingViewModel: makeLeadingViewModel(from: paymentMethod.urn),
            action: Action(
                title: paymentMethod.ctaText ?? L10n.PaymentRequest.Create.PaymentMethods.RequiresUserAction.title,
                handler: { [weak self] in
                    guard let self else {
                        return
                    }
                    routingDelegate?.showDynamicFormsMethodManagement(forms, delegate: delegate)
                }
            )
        )
        return .actionOptionViewModel(viewModel)
    }

    func makeOptionViewModels() -> [CreatePaymentRequestMethodManagementViewModel.OptionViewModel] {
        paymentMethodsAvailability.paymentMethods.compactMap { method in
            if case let .requiresUserAction(dynamicForms: forms) = method.unavailabilityReason {
                makeRequiresUserActionOptionViewModel(paymentMethod: method, forms: forms)
            } else if method.type == .payWithWise {
                makePayWithWiseViewModel(paymentMethod: method)
            } else if method.available {
                makeAvailableOptionViewModel(paymentMethod: method)
            } else {
                makeUnavailableOptionViewModel(paymentMethod: method)
            }
        }
    }
}
