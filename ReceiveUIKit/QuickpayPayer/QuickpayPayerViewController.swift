import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
// sourcery: baseClass = "LoadingPresentableMock"
protocol QuickpayPayerView: AnyObject, LoadingPresentable {
    func configure(with viewModel: QuickpayPayerViewModel)
    func configureError(with viewModel: ErrorViewModel)
    func updateSelectedCurrency(currency: CurrencyCode)
    func moneyInputError(_ message: String)
    func descriptionInputError(_ message: String)
    func footerButtonState(enabled: Bool)
}

final class QuickpayPayerViewController: LCEBottomSheetViewController {
    private let presenter: QuickpayPayerPresenter

    private lazy var headerView = QuickpayPayerHeaderView()
    private var moneyInputViewModel = MoneyInputViewModel() {
        didSet {
            moneyInput.configure(with: moneyInputViewModel)
        }
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

    private lazy var referenceView = StackTextInputView().with {
        $0.label = L10n.QuickpayPayer.BusinessInfo.descriptionInput
        $0.onChange = { [weak self] input in
            self?.presenter.descriptionValueUpdated(_text: input)
        }
    }

    // MARK: - Life cycle

    init(presenter: QuickpayPayerPresenter) {
        self.presenter = presenter
        super.init(refreshAction: {})
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.start(with: self)
    }
}

extension QuickpayPayerViewController: QuickpayPayerView {
    func configure(with viewModel: QuickpayPayerViewModel) {
        tw_contentUnavailableConfiguration = nil
        primaryAction = nil
        headerView.configure(with: viewModel)
        moneyInputViewModel = viewModel.moneyInputViewModel

        moneyInput.enableCurrencySelector(
            tapHint: "",
            tapAction: { [weak self] in
                self?.presenter.moneyInputCurrencyTapped()
            }
        )

        if let description = viewModel.description {
            referenceView.text = description
            referenceView.isEditable = false
            referenceView.isEnabled = false
        } else {
            referenceView.text = nil
            referenceView.isEditable = true
            referenceView.isEnabled = true
        }

        footerConfiguration = .simple(separatorHidden: .always)
        primaryAction = LargeButtonView.ViewModel(
            title: L10n.QuickpayPayer.FotterButton.title,
            handler: { [weak self] in
                self?.continueTapped()
            }
        )

        arrangedSubviews = [
            headerView,
            moneyInput,
            referenceView,
        ]
    }

    func configureError(with viewModel: ErrorViewModel) {
        primaryAction = nil
        tw_contentUnavailableConfiguration = .error(viewModel)
    }

    func updateSelectedCurrency(currency: CurrencyCode) {
        moneyInputViewModel = moneyInputViewModel.applying(
            currencyName: currency.value,
            currencyAccessibilityName: currency.localizedCurrencyName,
            flagImage: currency.icon
        )
    }

    func moneyInputError(_ message: String) {
        moneyInputViewModel = moneyInputViewModel.applying(panelText: .error(message))
    }

    func descriptionInputError(_ message: String) {
        referenceView.view.error = message
    }

    func continueTapped() {
        view.endEditing(true)

        guard let inputAmount = moneyInputViewModel.amount,
              let amount = MoneyFormatter.number(inputAmount)?.decimalValue else {
            return
        }

        let inputs = QuickpayPayerInputs(
            amount: amount,
            currency: moneyInputViewModel.currencyName,
            description: referenceView.text
        )
        presenter.continueTapped(inputs: inputs)
    }

    func footerButtonState(enabled: Bool) {
        primaryAction?.isEnabled = enabled
    }
}
