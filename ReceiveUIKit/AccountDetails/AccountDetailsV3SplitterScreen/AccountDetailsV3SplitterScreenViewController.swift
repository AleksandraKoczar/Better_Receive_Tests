import Neptune
import TransferResources
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsV3SplitterScreenListView: AnyObject {
    func configure(with: AccountDetailsV3SplitterScreenViewModel)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func showHud()
    func hideHud()
}

final class AccountDetailsV3SplitterScreenViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: AccountDetailsV3SplitterScreenPresenter

    init(presenter: AccountDetailsV3SplitterScreenPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(
        arrangedSubviews: [accountDetailsSplitterStackView],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault
    )

    private lazy var accountDetailsSplitterStackView = UIStackView()
        .with {
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(
                vertical: theme.spacing.vertical.componentDefault,
                horizontal: theme.spacing.horizontal.componentDefault
            )
        }

    private lazy var currencySelectorView: AccountDetailsV3CurrencySelectorView = {
        let view = AccountDetailsV3CurrencySelectorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var avatarView = AvatarView().with {
        $0.setStyle(.size40)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
    }
}

extension AccountDetailsV3SplitterScreenViewController: AccountDetailsV3SplitterScreenListView {
    func configure(with viewModel: AccountDetailsV3SplitterScreenViewModel) {
        tw_contentUnavailableConfiguration = nil
        configureSplitterView(with: viewModel)
        configureNavigationBar(with: viewModel.currency)
    }

    private func configureSplitterView(
        with viewModel: AccountDetailsV3SplitterScreenViewModel
    ) {
        accountDetailsSplitterStackView.removeAllArrangedSubviews()
        let splitterView = AccountDetailsV3SplitterScreenView(model: viewModel)
        let controller = SwiftUIHostingController<AccountDetailsV3SplitterScreenView>(
            content: { splitterView }
        )
        accountDetailsSplitterStackView.addArrangedSubviews(controller.view)
        accountDetailsSplitterStackView.alignment = .center
        accountDetailsSplitterStackView.distribution = .fill
    }

    private func configureNavigationBar(with currency: CurrencyCode) {
        let model = AccountDetailsV3CurrencySelectorViewModel(
            title: currency.value,
            subtitle: L10n.AccountDetailsV3.Header.subtitle,
            currency: currency,
            isOnTapEnabled: false,
            onTap: {}
        )
        currencySelectorView.configure(with: model)

        if let flag = makeFlagImage(currencyString: currency.value) {
            avatarView.configure(
                with: AvatarViewModel.image(flag)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarView)
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        navigationItem.titleView = currencySelectorView
    }

    private func makeFlagImage(currencyString: String) -> UIImage? {
        guard let urn = try? URN("urn:wise:currencies:\(currencyString):image"),
              let image = FlagFactory.flag(urn: urn) else {
            return nil
        }
        return image
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }
}
