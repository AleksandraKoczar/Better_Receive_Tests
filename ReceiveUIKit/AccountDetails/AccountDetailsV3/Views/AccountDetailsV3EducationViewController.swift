import Neptune
import TWUI

struct AccountDetailsV3EducationViewModel {
    let title: String
    let body: MarkdownLabel
    let action: Action?
}

final class AccountDetailsV3EducationViewController: AbstractViewController, OptsIntoAutoBackButton {
    private enum Constants {
        static let stackViewInsets = UIEdgeInsets(top: 0, left: .defaultMargin, bottom: .defaultMargin, right: .defaultMargin)
    }

    // MARK: - Properties

    private let model: AccountDetailsV3EducationViewModel

    // MARK: - Init

    init(model: AccountDetailsV3EducationViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Public Interface

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {
        edgesForExtendedLayout = []
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubviews([headerView, .spacer(.defaultSpacing), text])

        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -.defaultMargin * 2).isActive = true

        if model.action != nil {
            view.addSubview(footerView)
        }
        scrollView.constrainToSuperview(.safeContentArea)
    }

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: Constants.stackViewInsets
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var stackView = UIStackView(
        axis: .vertical
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var text: MarkdownLabel = model.body

    private lazy var headerView: LargeTitleView = {
        let t = LargeTitleView(
            scrollObserver: scrollView.scrollObserver(),
            delegate: self
        )
        t.configure(with: LargeTitleViewModel(title: model.title))
        return t
    }()

    private lazy var footerView: FooterView = {
        let footerView = FooterView(configuration: .simple(button: .secondary))
        footerView.primaryViewModel = .init(model.action)
        return footerView
    }()
}
