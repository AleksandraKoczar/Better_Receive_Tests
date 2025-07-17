import LoggingKit
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
// sourcery: baseClass = "LoadingPresentableMock"
protocol CreatePaymentRequestPersonalView: AnyObject, LoadingPresentable {
    func configure(with viewModel: CreatePaymentRequestPersonalViewModel)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func configureContact(with viewModel: OptionViewModel?)
    func updateSelectedCurrency(currency: CurrencyCode)
    func calculatorError(_ errorMsg: String)
    func showMessageInputError(_ errorMessage: String)
    func dismissMessageInputError()
    func footerButtonState(enabled: Bool)
    func hideNudge()
    func showDismissableAlert(
        title: String,
        message: String
    )
    func showHud()
    func hideHud()
}

final class CreatePaymentRequestPersonalViewController: LCEViewController, OptsIntoAutoBackButton {
    private typealias Localization = L10n.PaymentRequest.Create

    private let presenter: CreatePaymentRequestPersonalPresenter
    private let keyboardDismisser = KeyboardDismisser()
    private var moneyInputViewModel = MoneyInputViewModel() {
        didSet {
            moneyInput.configure(with: moneyInputViewModel)
        }
    }

    init(presenter: CreatePaymentRequestPersonalPresenter) {
        self.presenter = presenter
        super.init(refreshAction: {})
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "CreatePaymentRequestPersonalView"
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

    private func sendRequestTapped() {
        view.endEditing(true)
        presenter.sendRequestTapped(note: messageInput.text)
    }

    private func configureMessage(with message: String?) {
        if let message {
            messageInput.text = message
        }
        stackView.showArrangedSubviews([messageInput])
    }

    private func configureNudge(with nudge: CreatePaymentRequestPersonalViewModel.Nudge?) {
        guard let nudge else {
            stackView.hideArrangedSubviews([nudgeView])
            return
        }

        let viewModel = NudgeViewModel(
            title: nudge.title,
            asset: nudge.icon,
            ctaTitle: nudge.ctaTitle,
            onSelect: { [weak self] in
                self?.presenter.nudgeSelected()
            },
            onDismiss: { [weak self] in
                self?.presenter.nudgeCloseTapped()
            }
        )
        nudgeView.configure(with: viewModel)
        stackView.showArrangedSubviews([nudgeView])
    }

    private func configureAlert(with alert: CreatePaymentRequestPersonalViewModel.Alert?) {
        guard let alert else {
            stackView.hideArrangedSubviews([inlineAlertView])
            return
        }

        inlineAlertView.configure(with: alert.viewModel)
        inlineAlertView.setStyle(alert.style)
        stackView.showArrangedSubviews([inlineAlertView])
    }

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: .horizontal(.defaultMargin)
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var stackView = UIStackView(arrangedSubviews: [
        headerView,
        postHeaderViewSpacingView,
        contactListItemView,
        moneyInput,
        messageInput,
        inlineAlertView,
        nudgeView,
    ])
    .with {
        $0.axis = .vertical
        $0.spacing = theme.spacing.vertical.componentDefault
    }

    private lazy var headerView = LargeTitleView()

    private lazy var messageInput = Neptune.TextView().with {
        $0.delegate = self
        $0.label = Localization.Message.placeholder
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

    private lazy var footerView = FooterView().with {
        $0.primaryViewModel = .init(
            title: "",
            handler: { [weak self] in
                self?.sendRequestTapped()
            }
        )
    }

    private lazy var contactListItemView = OptionView().with {
        $0.isHidden = true
    }

    private lazy var postHeaderViewSpacingView = UIView.spacer(theme.spacing.vertical.betweenText)

    private let nudgeView = NudgeView()

    private let inlineAlertView = InlineAlertView(style: .neutral)
}

// MARK: - CreatePaymentRequestPersonalView

extension CreatePaymentRequestPersonalViewController: CreatePaymentRequestPersonalView {
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

    func showMessageInputError(_ errorMessage: String) {
        messageInput.setStyle(.error)
        messageInput.info = errorMessage
    }

    func dismissMessageInputError() {
        guard messageInput.info != nil else {
            return
        }
        messageInput.setStyle(.default)
        messageInput.info = nil
    }

    func hideNudge() {
        stackView.hideArrangedSubviews([nudgeView])
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        footerView.removeFromSuperview()
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func configure(with viewModel: CreatePaymentRequestPersonalViewModel) {
        headerView.configure(with: viewModel.titleViewModel)
        moneyInputViewModel = viewModel.moneyInputViewModel
        view.addSubview(footerView)
        footerView.primaryViewModel?.isEnabled = viewModel.footerButtonEnabled
        footerView.primaryViewModel?.title = viewModel.footerButtonTitle
        configureMessage(with: viewModel.message)
        configureAlert(with: viewModel.alert)
        configureNudge(with: viewModel.nudge)
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

    func configureContact(with viewModel: OptionViewModel?) {
        if let optionViewModel = viewModel {
            stackView.showArrangedSubviews([contactListItemView])
            contactListItemView.configure(with: optionViewModel)
        } else {
            stackView.hideArrangedSubviews([contactListItemView])
        }
    }

    func footerButtonState(enabled: Bool) {
        footerView.primaryViewModel?.isEnabled = enabled
    }
}

// MARK: - UITextFieldDelegate

extension CreatePaymentRequestPersonalViewController: UITextFieldDelegate {
    private func getUpdatedText(
        from text: String?,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> String? {
        let currentText = text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return nil
        }
        return currentText.replacingCharacters(in: stringRange, with: string)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        false
    }
}

// MARK: - UITextViewDelegate

extension CreatePaymentRequestPersonalViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard let updatedText = getUpdatedText(
            from: textView.text,
            shouldChangeCharactersIn: range,
            replacementString: text
        ) else {
            return false
        }
        return presenter.isValidPersonalMessage(updatedText)
    }
}

// MARK: - HasPreDismissAction

extension CreatePaymentRequestPersonalViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: DismissActionType) {
        if type == .modalDismissal {
            presenter.dismiss()
        }
    }
}
