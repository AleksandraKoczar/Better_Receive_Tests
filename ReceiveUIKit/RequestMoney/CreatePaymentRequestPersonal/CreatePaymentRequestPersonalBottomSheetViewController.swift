import LoggingKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

final class CreatePaymentRequestPersonalBottomSheetViewController: LCEBottomSheetViewController {
    private typealias Localization = L10n.PaymentRequest.Create

    private let presenter: CreatePaymentRequestPersonalPresenter

    private var moneyInputViewModel = MoneyInputViewModel() {
        didSet {
            moneyInput.configure(with: moneyInputViewModel)
        }
    }

    // MARK: - Subviews

    private lazy var headerView = LargeTitleView().with {
        $0.configure(with: LargeTitleViewModel(
            title: Localization.BottomSheet.Header.title,
            description: Localization.BottomSheet.Header.description
        ))
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var messageInput = StackTextView().with {
        $0.delegate = self
        $0.label = Localization.BottomSheet.Message.placeholder
    }

    private lazy var moneyInput = StackMoneyInputView(
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

    private let inlineAlertView = StackInlineAlertView()

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
        arrangedSubviews = [
            headerView,
            moneyInput,
            messageInput,
            inlineAlertView,
        ]
        stackView.spacing = theme.spacing.vertical.componentDefault
        presenter.start(with: self)
    }

    // MARK: - Helpers

    private func continueTapped() {
        view.endEditing(true)
        presenter.sendRequestTapped(note: messageInput.text)
    }

    private func configureMessage(with message: String?) {
        if let message {
            messageInput.text = message
        }
        stackView.showArrangedSubviews([messageInput])
    }
}

// MARK: - CreatePaymentRequestPersonalView

extension CreatePaymentRequestPersonalBottomSheetViewController: CreatePaymentRequestPersonalView {
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

    func configureWithError(with errorViewModel: ErrorViewModel) {
        primaryAction = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func configure(with viewModel: CreatePaymentRequestPersonalViewModel) {
        moneyInputViewModel = viewModel.moneyInputViewModel

        footerConfiguration = .simple(separatorHidden: .always)
        primaryAction?.isEnabled = viewModel.footerButtonEnabled

        primaryAction = .init(
            title: Localization.BottomSheet.Button.title,
            handler: { [weak self] in
                self?.continueTapped()
            }
        )

        configureMessage(with: viewModel.message)
        configureAlert(with: viewModel.alert)
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

    private func configureAlert(with alert: CreatePaymentRequestPersonalViewModel.Alert?) {
        guard let alert else {
            stackView.hideArrangedSubviews([inlineAlertView])
            return
        }

        inlineAlertView.configure(with: alert.viewModel)
        inlineAlertView.setStyle(alert.style)
        stackView.showArrangedSubviews([inlineAlertView])
    }

    func footerButtonState(enabled: Bool) {
        primaryAction?.isEnabled = enabled
    }

    func configureContact(with viewModel: OptionViewModel?) {}

    func hideNudge() {}
}

// MARK: - UITextFieldDelegate

extension CreatePaymentRequestPersonalBottomSheetViewController: UITextFieldDelegate {
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

extension CreatePaymentRequestPersonalBottomSheetViewController: UITextViewDelegate {
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
