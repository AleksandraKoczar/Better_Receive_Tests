import Neptune
import TWFoundation
import TWUI

protocol AccountDetailsInfoIntroView: SemanticContext {
    func configure(viewModel: AccountDetailsInfoIntroViewModel)
    func showHud()
    func hideHud()
    func showErrorAlert(title: String, message: String)
}

final class AccountDetailsInfoIntroViewController: AbstractViewController, HasPostStandardDismissAction {
    private enum Constants {
        static let rowValueStyle = LabelStyle.defaultBody
    }

    // MARK: - Views

    private lazy var headerView = LargeTitleView(
        scrollObserver: scrollView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.padding.horizontal
    )

    private lazy var scrollView = UIScrollView(
        contentView: stackView
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var stackView = UIStackView(
        axis: .vertical,
        spacing: 0
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let infoView = AccountDetailsReceiveOptionInfoView()

    // MARK: - Properties

    private let presenter: AccountDetailsInfoIntroPresenter
    private var viewModel: AccountDetailsInfoIntroViewModel?

    // MARK: - Lifecycle

    init(presenter: AccountDetailsInfoIntroPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        presenter.start(view: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        accessibilityElements = [
            headerView.accessibilityElements,
            stackView.accessibilityElements,
        ].lazy
            .compactMap { $0 }
            .flatMap { $0 }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory,
              let viewModel else {
            return
        }
        configure(viewModel: viewModel)
    }

    func performPostStandardDismissAction(ofType type: DismissActionType) {
        presenter.dismiss()
    }
}

// MARK: - AccountDetailsInfoIntroView

extension AccountDetailsInfoIntroViewController: AccountDetailsInfoIntroView {
    func configure(viewModel: AccountDetailsInfoIntroViewModel) {
        self.viewModel = viewModel
        stackView.removeAllArrangedSubviews()

        stackView.addArrangedSubview(headerView)
        headerView.configure(with: viewModel.title)

        if let infoViewModel = viewModel.infoViewModel {
            stackView.addArrangedSubviews([
                .spacer(theme.spacing.vertical.textToComponent),
                infoView,
            ])
            infoView.configure(with: infoViewModel)
            infoView.padding = .init(horizontal: .defaultMargin)
        }

        let sectionHeader = StackSectionHeaderView()
        sectionHeader.configure(with: viewModel.sectionHeader)
        stackView.addArrangedSubview(sectionHeader)

        viewModel.navigationActions.forEach {
            let view = StackNavigationOptionView()
            view.configure(with: $0.viewModel)
            view.onTap = $0.action
            stackView.addArrangedSubview(view)
        }
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoIntroViewController {
    func setupViews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
    }
}
