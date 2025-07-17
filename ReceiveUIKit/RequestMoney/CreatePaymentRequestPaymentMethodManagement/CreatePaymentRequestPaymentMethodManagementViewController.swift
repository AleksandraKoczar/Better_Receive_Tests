import LoggingKit
import TransferResources
import TWUI

// sourcery: AutoMockable
protocol CreatePaymentRequestPaymentMethodManagementView: AnyObject {
    func configure(with viewModel: CreatePaymentRequestMethodManagementViewModel)
}

final class CreatePaymentRequestPaymentMethodManagementViewController: BottomSheetViewController {
    private let presenter: CreatePaymentRequestPaymentMethodManagementPresenter

    // MARK: - Subviews

    private lazy var titleLabel = StackLabel().with {
        $0.setStyle(\.sectionTitle)
        $0.padding = .horizontal(.defaultMargin)
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(\.largeBody)
        $0.textAlignment = .left
        $0.padding = .horizontal(.defaultMargin)
    }

    private lazy var optionsStackView = UIStackView(
        axis: .vertical
    )

    // MARK: - Lifecycle

    init(presenter: CreatePaymentRequestPaymentMethodManagementPresenter) {
        self.presenter = presenter
        super.init(arrangedSubviews: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrangedSubviews = [titleLabel, subtitleLabel, optionsStackView]
        stackView.spacing = theme.spacing.vertical.betweenText
        presenter.start(with: self)
    }
}

extension CreatePaymentRequestPaymentMethodManagementViewController: CreatePaymentRequestPaymentMethodManagementView {
    func configure(with viewModel: CreatePaymentRequestMethodManagementViewModel) {
        titleLabel.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)

        viewModel.options.forEach { option in
            switch option {
            case let .switchOptionViewModel(switchOptionViewModel):
                configureSwitchOptionView(switchOptionViewModel)
            case let .payWithWiseOptionViewModel(optionViewModel):
                configureOptionView(optionViewModel)
            case let .actionOptionViewModel(actionOptionViewModel):
                configureActionOptionView(actionOptionViewModel)
            }
        }

        footerConfiguration = .extended(
            primaryView: .primary,
            secondaryView: .secondaryNeutral
        )
        primaryAction = .init(viewModel.footerAction)
        secondaryAction = .init(viewModel.secondaryFooterAction)
    }
}

private extension CreatePaymentRequestPaymentMethodManagementViewController {
    func configureActionOptionView(
        _ actionOptionViewModel: CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel
    ) {
        let actionView = StackActionOptionView()
        actionView.configure(
            with: ActionOptionViewModel(
                model: OptionViewModel(
                    title: actionOptionViewModel.title,
                    subtitle: actionOptionViewModel.subtitle,
                    leadingView: actionOptionViewModel.leadingViewModel,
                ),
                button: .init(action: actionOptionViewModel.action)
            )
        )
        actionView.setStyle(.smallSecondaryNeutral)
        optionsStackView.addArrangedSubview(actionView)
    }

    func configureSwitchOptionView(
        _ optionViewModel: CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel
    ) {
        let switchView = StackSwitchOptionView()
        switchView.configure(
            with: SwitchOptionViewModel(
                model: OptionViewModel(
                    title: optionViewModel.title,
                    subtitle: optionViewModel.subtitle,
                    leadingView: optionViewModel.leadingViewModel,
                ),
                isOn: optionViewModel.isOn
            )
        )
        switchView.onToggle = optionViewModel.onToggle
        switchView.isEnabled = optionViewModel.isEnabled
        optionsStackView.addArrangedSubview(switchView)
    }

    func configureOptionView(
        _ optionViewModel: OptionViewModel
    ) {
        let optionView = StackOptionView()
        optionView.configure(with: optionViewModel)
        optionsStackView.addArrangedSubview(optionView)
    }
}
