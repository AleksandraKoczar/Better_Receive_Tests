import Neptune
import UIKit

// sourcery: AutoMockable
protocol AccountDetailsV3ListView: AnyObject {
    func configure(with: AccountDetailsV3ListViewModel)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func showHud()
    func hideHud()
    func hideLoading()
}

final class AccountDetailsV3ListViewController: LCEViewController, OptsIntoAutoBackButton {
    private let presenter: AccountDetailsV3ListPresenter

    init(presenter: AccountDetailsV3ListPresenter) {
        self.presenter = presenter
        super.init(refreshAction: presenter.refresh)
    }

    private lazy var scrollView = UIScrollView(contentView: stackView)
    private lazy var accountDetailsListStackView = UIStackView()

    private lazy var stackView = UIStackView(
        arrangedSubviews: [accountDetailsListStackView],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
        contentScrollView = scrollView
        pullToRefreshIsEnabled = true
    }

    func hideLoading() {
        loadingStopped(hasContent: true, hasError: false)
    }
}

extension AccountDetailsV3ListViewController: AccountDetailsV3ListView {
    func configure(with viewModel: AccountDetailsV3ListViewModel) {
        tw_contentUnavailableConfiguration = nil
        configureAccountDetailsList(with: viewModel)
    }

    func configureAccountDetailsList(
        with viewModel: AccountDetailsV3ListViewModel
    ) {
        accountDetailsListStackView.removeAllArrangedSubviews()
        let accountDetailsListView = AccountDetailsV3ListContainerView(model: viewModel)
        let controller = SwiftUIHostingController<AccountDetailsV3ListContainerView>(
            content: { accountDetailsListView }
        )
        accountDetailsListStackView.addArrangedSubviews(controller.view)
        accountDetailsListStackView.alignment = .center
        accountDetailsListStackView.distribution = .fill
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }
}
