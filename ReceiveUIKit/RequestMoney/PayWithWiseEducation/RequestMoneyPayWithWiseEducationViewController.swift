import LoggingKit
import TWUI

// sourcery: AutoMockable
protocol RequestMoneyPayWithWiseEducationView: AnyObject {
    func configure(with viewModel: RequestMoneyPayWithWiseEducationViewModel)
}

final class RequestMoneyPayWithWiseEducationViewController: UIViewController {
    private let presenter: RequestMoneyPayWithWiseEducationPresenter

    // MARK: - Subviews

    private let imageView = UIImageView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentMode = .scaleAspectFit
    }

    private let titleView = LargeTitleView().with {
        $0.setStyle(LargeTitleStyle.screen.centered)
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(LabelStyle.largeBody.centered)
    }

    private lazy var descriptionLabel = StackMarkupLabel().with {
        $0.setStyle(LabelStyle.largeBody.centered)
        $0.padding = .vertical(theme.spacing.vertical.betweenText)
    }

    private let primaryButton = StackButton()

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            imageView,
            titleView,
            subtitleLabel,
            descriptionLabel,
            primaryButton,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.betweenText
    )

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: .horizontal(theme.spacing.horizontal.componentDefault)
    )

    // MARK: - Lifecycle

    init(presenter: RequestMoneyPayWithWiseEducationPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }
}

// MARK: - Helpers

private extension RequestMoneyPayWithWiseEducationViewController {
    func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    func configureDescriptionLabel(with description: RequestMoneyPayWithWiseEducationViewModel.MarkupLabel?) {
        guard let description else {
            stackView.hideArrangedSubviews([descriptionLabel])
            return
        }
        let textModel = MarkupLabelModel(
            text: description.text,
            action: MarkupTapAction(
                accessibilityActionName: description.text,
                handler: {
                    description.action()
                }
            )
        )
        descriptionLabel.configure(with: MarkupLabel.Model(model: .markup(textModel)))
        stackView.showArrangedSubviews([descriptionLabel])
    }
}

// MARK: - RequestMoneyPayWithWiseEducationView

extension RequestMoneyPayWithWiseEducationViewController: RequestMoneyPayWithWiseEducationView {
    func configure(with viewModel: RequestMoneyPayWithWiseEducationViewModel) {
        imageView.image = viewModel.image
        titleView.configure(title: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)
        configureDescriptionLabel(with: viewModel.description)
        primaryButton.setAction(viewModel.action)
    }
}
