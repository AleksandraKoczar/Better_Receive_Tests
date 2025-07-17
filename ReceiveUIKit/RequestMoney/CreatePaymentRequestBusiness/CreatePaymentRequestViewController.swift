import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestView: AnyObject {
    func configure(with viewModel: CreatePaymentRequestViewModel)
    func updateSelectedCurrency(currency: CurrencyCode)
    func calculatorError(_ errorMsg: String)
    func footerButtonState(enabled: Bool)
    func updatePaymentMethodOption(option: CreatePaymentRequestViewModel.PaymentMethodsOption)
    func updateNudge(_ nudge: NudgeViewModel?)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func showHud()
    func hideHud()
}

final class CreatePaymentRequestViewController: AbstractViewController, OptsIntoAutoBackButton {
    private typealias Localization = L10n.PaymentRequest.Create

    private let presenter: CreatePaymentRequestPresenter
    private let keyboardDismisser = KeyboardDismisser()
    private var moneyInputViewModel = MoneyInputViewModel() {
        didSet {
            moneyInput.configure(with: moneyInputViewModel)
        }
    }

    init(presenter: CreatePaymentRequestPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "CreatePaymentRequestView"
        presenter.start(with: self)
        setupSubviews()
        keyboardDismisser.attach(toView: view)
    }

    // MARK: - Helpers

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
        view.addSubview(footerView)
    }

    private func continueTapped() {
        view.endEditing(true)
        let inputs = CreatePaymentRequestInputs(
            reference: nil,
            productDescription: productInput.text
        )
        presenter.continueTapped(inputs: inputs)
    }

    private func configureDescription(with productDescription: String?) {
        if let productDescription {
            productInput.text = productDescription
        }
    }

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(arrangedSubviews: [
        headerView,
        inputsStackView,
        settingsStackView,
    ])
    .with {
        $0.axis = .vertical
        $0.spacing = theme.spacing.horizontal.value24
    }

    private lazy var inputsStackView = UIStackView(arrangedSubviews: [
        moneyInput,
        productInput,
    ])
    .with {
        $0.axis = .vertical
        $0.spacing = theme.spacing.horizontal.componentDefault
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var separatorStackView = UIStackView(arrangedSubviews: [
        separatorView,
    ])
    .with {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var separatorView = UIView().with {
        $0.backgroundColor = theme.color.background.neutral.normal
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private lazy var settingsStackView = UIStackView(arrangedSubviews: [
        separatorStackView,
        limitPaymentsCheckbox,
        paymentMethodsListItem,
        nudgeView,
    ])
    .with {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.spacing = theme.spacing.horizontal.value8
    }

    private lazy var headerView = LargeTitleView().with {
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var productInput = TextInputView().with {
        $0.label = Localization.Description.placeholder
    }

    private lazy var moneyInput = MoneyInputView(
        model: self.moneyInputViewModel,
        inputFormatter: MoneyAsYouTypeFormatterImpl(locale: Locale.current),
        inputCallbacks: MoneyInputView.InputCallbacks(
            startedEditing: { [weak self] _ in
                guard let self else { return }
                moneyInputViewModel = moneyInputViewModel.applying(panelText: MoneyInputViewModel.PanelTextType.none)
            },
            updated: { [weak self] value in
                guard let self else { return }
                moneyInputViewModel = moneyInputViewModel.applying(amount: value)
                presenter.moneyValueUpdated(value)
            }
        )
    )

    private lazy var limitPaymentsCheckbox = StackCheckboxOptionView().with {
        $0.configure(with: .init(model: OptionViewModel(
            title: Localization.LimitPayment.title,
            leadingView: .avatar(._icon(Icons.limit.image, badge: nil))
        )))
        $0.onTap = { [weak self] in
            self?.presenter.togglePaymentLimit()
        }
    }

    private let paymentMethodsListItem = StackNavigationOptionView().with {
        $0.view.setLeadingAvatarViewStyle(.size48.with {
            $0.alignment = .diagonal
        })
    }

    private let nudgeView = StackNudgeView().with {
        $0.padding = .horizontal(.defaultMargin)
        $0.isHidden = true
    }

    private lazy var footerView = FooterView().with {
        $0.primaryViewModel = .init(
            title: "",
            handler: { [weak self] in
                self?.continueTapped()
            }
        )
    }
}

// MARK: - CreatePaymentRequestView

extension CreatePaymentRequestViewController: CreatePaymentRequestView {
    func updateSelectedCurrency(currency: CurrencyCode) {
        moneyInputViewModel = moneyInputViewModel.applying(
            currencyName: currency.value,
            currencyAccessibilityName: currency.localizedCurrencyName,
            flagImage: currency.icon
        )
    }

    func calculatorError(_ errorMsg: String) {
        moneyInputViewModel = moneyInputViewModel.applying(panelText: .error(errorMsg))
    }

    func updatePaymentMethodOption(option: CreatePaymentRequestViewModel.PaymentMethodsOption) {
        paymentMethodsListItem.configure(with: option.viewModel)
        paymentMethodsListItem.onTap = option.onTap
    }

    func updateNudge(_ nudge: NudgeViewModel?) {
        if let nudge {
            nudgeView.configure(with: nudge)
            nudgeView.isHidden = false
        } else {
            nudgeView.isHidden = true
        }
    }

    func configure(with viewModel: CreatePaymentRequestViewModel) {
        headerView.configure(with: viewModel.titleViewModel)
        moneyInputViewModel = viewModel.moneyInputViewModel
        configureDescription(with: viewModel.productDescription)
        limitPaymentsCheckbox.isSelected = viewModel.isLimitPaymentsSelected

        if viewModel.shouldShowPaymentLimitsCheckbox == false {
            stackView.hideArrangedSubviews([limitPaymentsCheckbox])
        }

        paymentMethodsListItem.configure(with: viewModel.paymentMethodsOption.viewModel)
        paymentMethodsListItem.onTap = viewModel.paymentMethodsOption.onTap

        footerView.primaryViewModel?.isEnabled = viewModel.footerButtonEnabled
        footerView.primaryViewModel?.title = viewModel.footerButtonTitle

        if viewModel.currencySelectorEnabled {
            moneyInput.enableCurrencySelector(
                tapHint: Localization.Select.currency,
                tapAction: { [weak self] in
                    self?.presenter.moneyInputCurrencyTapped()
                }
            )
        } else {
            moneyInput.disableCurrencySelector()
        }
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func footerButtonState(enabled: Bool) {
        footerView.primaryViewModel?.isEnabled = enabled
    }
}

// MARK: - HasPreDismissAction

extension CreatePaymentRequestViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: DismissActionType) {
        if type == .modalDismissal {
            presenter.dismiss()
        }
    }
}
