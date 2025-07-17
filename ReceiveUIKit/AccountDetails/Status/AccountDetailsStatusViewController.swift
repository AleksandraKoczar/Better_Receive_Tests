import Neptune
import ReceiveKit
import TransferResources
import TWUI

// sourcery: AutoMockable
protocol AccountDetailsStatusView: AnyObject {
    func configure(with state: AccountDetailsStatusViewState)
}

// sourcery: Buildable
enum AccountDetailsStatusViewState: Equatable {
    // sourcery: Buildable
    struct Model: Equatable {
        let header: AccountDetailsStatusHeader
        let status: AccountDetailsStatus
    }

    case failedToLoad(ErrorViewModel)
    case loaded(Model)
    case loading
}

final class AccountDetailsStatusViewController: LCEViewController {
    private let presenter: AccountDetailsStatusPresenter

    private var state: AccountDetailsStatusViewState = .loading {
        didSet {
            configureView()
        }
    }

    private lazy var scrollView = UIScrollView(
        contentView: stackView
    )

    private let stackView = UIStackView(
        axis: .vertical
    )

    private lazy var headerView = LargeTitleView(
        scrollObserver: scrollView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.padding
    )

    private let inlineAlertView = InlineAlertView(style: .neutral).with {
        $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    private let inlineAlertContainer = UIView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let sectionsView = UIStackView(
        axis: .vertical
    )

    private lazy var footerView = FooterView()

    init(
        presenter: AccountDetailsStatusPresenter
    ) {
        self.presenter = presenter
        super.init(refreshAction: presenter.refresh)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.configure(view: self)
    }
}

extension AccountDetailsStatusViewController: CustomDismissActionProvider {
    func provideCustomDismissAction(ofType type: DismissActionType) -> (() -> Void)? {
        { [weak self] in
            self?.presenter.dismissSelected()
        }
    }
}

extension AccountDetailsStatusViewController: AccountDetailsStatusView {
    func configure(with state: AccountDetailsStatusViewState) {
        self.state = state
    }
}

private extension AccountDetailsStatusViewController {
    func setupView() {
        inlineAlertContainer.addSubview(inlineAlertView)
        stackView.addArrangedSubviews([
            headerView,
            inlineAlertContainer,
            sectionsView,
        ])
        view.addSubview(scrollView)
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            inlineAlertView.topAnchor.constraint(equalTo: inlineAlertContainer.topAnchor),
            inlineAlertView.leadingAnchor.constraint(equalTo: inlineAlertContainer.leadingAnchor, constant: .defaultMargin),
            inlineAlertView.trailingAnchor.constraint(equalTo: inlineAlertContainer.trailingAnchor, constant: -.defaultMargin),
            inlineAlertView.bottomAnchor.constraint(equalTo: inlineAlertContainer.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }

    func configureView() {
        tw_contentUnavailableConfiguration = nil
        switch state {
        case .loading:
            showHud()
        case let .failedToLoad(errorViewModel):
            hideHud()
            showErrorStateView(with: errorViewModel)
        case let .loaded(model):
            hideHud()
            configureView(with: model)
        }
    }

    func showErrorStateView(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func configureView(
        with model: AccountDetailsStatusViewState.Model
    ) {
        scrollView.isHidden = false
        configure(header: model.header)
        configure(alert: model.status.alert)
        configure(sections: model.status.sections)
        configure(button: model.status.button)
    }

    func configure(header: AccountDetailsStatusHeader) {
        headerView.configure(
            with: .init(
                title: header.title,
                description: header.description
            )
        )
    }

    func configure(alert: AccountDetailsStatus.Alert?) {
        guard let alert else {
            inlineAlertContainer.isHidden = true
            return
        }
        inlineAlertView.configure(
            with: .init(message: alert.message)
        )
        inlineAlertView.setStyle({
            switch alert.style {
            case .positive:
                .positive
            case .neutral:
                .neutral
            case .negative:
                .negative
            case .warning:
                .warning
            }
        }())
        inlineAlertContainer.isHidden = false
    }

    func configure(sections: [AccountDetailsStatus.Section]) {
        sectionsView.removeAllArrangedSubviews()
        let views: [SectionView<SectionHeaderView, EmptyContentView>] = sections.map { section in
            SectionView(
                headerView: SectionHeaderViewModel(title: section.title),
                contentViews: section.summaries.map { summary in
                    StackSummaryView().with { view in
                        view.configure(with: SummaryViewModel(
                            title: summary.title,
                            description: summary.description,
                            icon: summary.icon,
                            status: {
                                switch summary.status {
                                case .done:
                                    .done
                                case .pending:
                                    .pending
                                case .later,
                                     .notDone,
                                     .unknown:
                                    .notDone
                                }
                            }(),
                            info: summary.info.flatMap { [weak self] info in
                                { self?.presenter.infoSelected(info: info) }
                            }
                        ))
                    }
                }
            )
        }
        sectionsView.addArrangedSubviews(views)
    }

    func configure(button: AccountDetailsStatus.Button?) {
        if let button {
            footerView.primaryViewModel = .init(
                title: button.title,
                handler: { [weak self] in
                    guard let self,
                          case let .loaded(model) = state,
                          let button = model.status.button else {
                        return
                    }
                    presenter.buttonSelected(action: button.action)
                }
            )
            footerView.isHidden = false
        } else {
            footerView.isHidden = true
        }
    }
}
