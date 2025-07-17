import Neptune
import TransferResources
import TWUI

final class AccountDetailsEducationViewController: AbstractViewController, OptsIntoAutoBackButton {
    private enum Constants {
        static let rowValueStyle = LabelStyle.defaultBody
        static let textStyle = LabelStyle.largeBody
        static let stackViewInsets = UIEdgeInsets(top: 0, left: .defaultMargin, bottom: 0, right: .defaultMargin)
    }

    // MARK: - Properties

    private let model: AccountDetailsBottomSheetViewModel

    // MARK: - Init

    init(model: AccountDetailsBottomSheetViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Public Interface

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        text.textStyle = Constants.textStyle
    }

    // MARK: - Private Interface

    private func setupSubviews() {
        edgesForExtendedLayout = []
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubviews([headerView, .spacer(.defaultSpacing), text])

        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -.defaultMargin * 2).isActive = true

        switch model.footerConfig?.type {
        case .revealed:
            view.addSubview(revealedView)
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(
                    equalTo: revealedView.topAnchor,
                    constant: -.defaultSpacing
                ),
                revealedView.leadingAnchor.constraint(
                    equalTo: view.leadingAnchor,
                    constant: .defaultMargin
                ),
                revealedView.trailingAnchor.constraint(
                    equalTo: view.trailingAnchor,
                    constant: -.defaultMargin
                ),
                revealedView.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor
                ),
            ])
        case .plainText:
            scrollView.constrainToSuperview(.safeContentArea)
            view.addSubview(footerView)
        case .none:
            scrollView.constrainToSuperview(.safeContentArea)
        }
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

    private lazy var text: HTMLTextView = {
        let l = HTMLTextView(style: Constants.textStyle)
        l.text = model.description
        l.urlHandler = model.action
        return l
    }()

    private lazy var headerView: LargeTitleView = {
        let t = LargeTitleView(
            scrollObserver: scrollView.scrollObserver(),
            delegate: self
        )
        if let title = model.title {
            t.configure(with: LargeTitleViewModel(title: title))
        }
        return t
    }()

    private lazy var footerView: FooterView = {
        let footerView = FooterView(configuration: .simple(button: .secondary))
        footerView.primaryViewModel = .init(Action(
            title: model.footerConfig?.title ?? "",
            handler: { [weak self] in
                self?.dismiss(animated: UIView.shouldAnimate) { [weak self] in
                    self?.model.footerConfig?.copyAction()
                }
            }
        ))
        return footerView
    }()

    private lazy var revealedView: UIView = {
        let marginView = UIView(frame: .zero)
        marginView.translatesAutoresizingMaskIntoConstraints = false
        marginView.backgroundColor = theme.color.background.screen.normal

        let greyView = UIView(frame: .zero)
        greyView.translatesAutoresizingMaskIntoConstraints = false
        greyView.backgroundColor = theme.color.background.overlay.normal
        greyView.layer.cornerRadius = 10
        greyView.addSubview(accountDetailsInfoRowView)
        accountDetailsInfoRowView.constrainToSuperview()

        marginView.addSubview(greyView)
        greyView.constrainToSuperview(
            insets: .vertical(.defaultMargin)
        )
        return marginView
    }()

    private lazy var accountDetailsInfoRowView: StackActionOptionView = {
        let view = StackActionOptionView()
        view.padding = UIEdgeInsets(value: .defaultMargin)
        view.backgroundColor = .clear
        if let footerConfig = model.footerConfig {
            view.configure(
                with: ActionOptionViewModel(
                    model: OptionViewModel(
                        title: footerConfig.title,
                        subtitle: footerConfig.value
                    ),
                    button: .init(
                        title: L10n.AccountDetails.Info.Details.Copy.Button.Copy.title,
                        handler: { footerConfig.copyAction() }
                    )
                )
            )
        }
        return view
    }()
}
