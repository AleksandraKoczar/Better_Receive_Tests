import LoggingKit
import TWUI

// sourcery: AutoMockable
protocol PaymentDetailsView: AnyObject {
    func configure(with viewModel: PaymentDetailsViewModel)
    func showHud()
    func hideHud()
    func showDismissableAlert(title: String, message: String)
}

final class PaymentDetailsViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: PaymentDetailsPresenter

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView)
    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            headerView,
            alertView,
            contentStackView,
        ],
        axis: .vertical,
        spacing: .defaultSpacing
    )

    private let headerView = LargeTitleView(padding: .horizontal(.defaultMargin))
    private let alertView = StackInlineAlertView()
    private let contentStackView = UIStackView(axis: .vertical).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(.defaultMargin)
    }

    private lazy var footerView = FooterView(configuration: .simple(button: .negative))

    // MARK: - Life cycle

    init(presenter: PaymentDetailsPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    // MARK: - Helpers

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    private func configureInlineAlert(viewModel: PaymentDetailsViewModel.Alert?) {
        guard let alert = viewModel else {
            alertView.isHidden = true
            return
        }
        alertView.isHidden = false
        alertView.setStyle(alert.style)
        alertView.configure(with: alert.viewModel)
    }

    private func configureListItems(viewModels: [PaymentDetailsViewModel.Item]) {
        for item in viewModels {
            switch item {
            case let .listItem(receiptItemViewModel):
                let receiptItemView = StackReceiptItemView()
                receiptItemView.configure(with: receiptItemViewModel)
                receiptItemView.padding = .vertical(.defaultMargin)
                contentStackView.addArrangedSubview(receiptItemView)
            case .separator:
                let separatorView = SeparatorView()
                contentStackView.addArrangedSubview(separatorView)
            }
        }
    }
}

// MARK: - PaymentDetailsView

extension PaymentDetailsViewController: PaymentDetailsView {
    func configure(with viewModel: PaymentDetailsViewModel) {
        headerView.configure(title: viewModel.title)
        configureInlineAlert(viewModel: viewModel.alert)

        contentStackView.removeAllArrangedSubviews()
        configureListItems(viewModels: viewModel.items)

        footerView.removeFromSuperview()
        if let action = viewModel.footerAction {
            footerView.primaryViewModel = .init(action)
            view.addSubview(footerView)
        }
    }
}
