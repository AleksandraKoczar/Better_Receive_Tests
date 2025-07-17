import Neptune
import TransferResources
import TWFoundation
import TWUI

struct FindFriendsViewModel: Equatable {
    let title: String
    let subtitle: String
    let asset: IllustrationView.Asset
}

final class FindFriendsViewController: AbstractViewController, OptsIntoAutoBackButton, ProvidesNavigationBarStyle, HasPreDismissAction {
    var preferredNavigationBarStyle: NavigationBarStyle? = .clear

    private enum Constants {
        static let animationDuration: CGFloat = 0.3
        static let iPadScrollViewHeightMultiplier: CGFloat = 0.8
        static let topButtonBottomConstraintCollapsed: CGFloat = tokens.value16
        static func topButtonBottomConstraint(buttonHeight: CGFloat) -> CGFloat {
            buttonHeight + tokens.value16 + tokens.value16
        }
    }

    private let viewModels: [FindFriendsViewModel]
    private var hadUserInteraction = false
    private weak var actionDelegate: FindFriendsActionDelegate?

    init(
        modelProvider: FindFriendsModelProvider,
        actionHandler: FindFriendsActionDelegate
    ) {
        viewModels = modelProvider.models
        actionDelegate = actionHandler
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        scrollView.delegate = self

        viewModels.forEach { model in
            self.setupView(model: model)
        }

        pageIndicator.numberOfPages = viewModels.count
    }

    func performPreDismissAction(ofType type: DismissActionType) {}

    private func primaryButtonTapped() {
        hadUserInteraction = true
        actionDelegate?.enableContactSync()
    }

    private func secondaryButtonTapped() {
        hadUserInteraction = true
        actionDelegate?.learnMoreButtonTapped()
    }

    private func setupView(model: FindFriendsViewModel) {
        let page = FindFriendsPageView()
        page.configure(model: model)
        stack.addArrangedSubview(page)
        page.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        page.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        page.layoutIfNeeded()
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        view.addSubview(pageIndicator)
        view.addSubview(separator)
        view.addSubview(primaryButton)
        view.addSubview(secondaryButton)
        stack.constrainToSuperview()
        scrollView.constrainToSuperview(.contentArea)

        let topButtonBottomConstraint = primaryButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -Constants.topButtonBottomConstraintCollapsed
        )

        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -tokens.value40
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicator.bottomAnchor.constraint(
                equalTo: separator.topAnchor,
                constant: -theme.spacing.vertical.componentDefault
            ),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.bottomAnchor.constraint(
                equalTo: primaryButton.topAnchor,
                constant: -theme.spacing.vertical.contentToButton
            ),
            primaryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: theme.spacing.horizontal.componentDefault
            ),
            primaryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -theme.spacing.horizontal.componentDefault
            ),
            topButtonBottomConstraint,
            secondaryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: theme.spacing.horizontal.componentDefault
            ),
            secondaryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -theme.spacing.horizontal.componentDefault
            ),
            secondaryButton.topAnchor.constraint(
                equalTo: primaryButton.bottomAnchor,
                constant: theme.spacing.vertical.componentDefault
            ),
        ])

        primaryButtonBottomConstraint = topButtonBottomConstraint
    }

    func pageUpdate(_ pageNumber: Int) {
        hadUserInteraction = true
        guard pageNumber < viewModels.count else {
            return
        }
        pageIndicator.currentPage = pageNumber
        if pageIndicator.currentPage == (viewModels.count - 1) {
            animateButtons(up: true)
        } else {
            animateButtons(up: false)
        }
    }

    private func animateButtons(up: Bool) {
        guard let primaryButtonBottomConstraint else {
            return
        }

        let topButtonBottomConstraint = Constants.topButtonBottomConstraint(buttonHeight: primaryButton.frame.height)
        primaryButtonBottomConstraint.constant = up ? -topButtonBottomConstraint : -Constants.topButtonBottomConstraintCollapsed
        secondaryButton.isHidden = up ? false : true
        UIView.animate(
            withDuration: UIView.shouldAnimate ? 0.3 : 0,
            animations: {
                self.view.layoutIfNeeded()
                self.secondaryButton.alpha = up ? 1.0 : 0.0
            }
        )
    }

    private var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.isPagingEnabled = true
        s.translatesAutoresizingMaskIntoConstraints = false
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceVertical = false
        s.alwaysBounceHorizontal = false
        s.showsVerticalScrollIndicator = false
        s.isDirectionalLockEnabled = true
        s.clipsToBounds = false
        return s
    }()

    private var stack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .leading
        return s
    }()

    private lazy var pageIndicator = UIPageControl().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.currentPage = 0
        $0.pageIndicatorTintColor = theme.color.background.neutral.normal
        $0.currentPageIndicatorTintColor = theme.color.interactive.primary.highlighted
    }

    private lazy var separator = SeparatorView().with {
        $0.setStyle(
            .solid()
        )
    }

    private var primaryButtonBottomConstraint: NSLayoutConstraint?
    private lazy var primaryButton: LargeButtonView = {
        let button = LargeButtonView(viewModel: .init(title: L10n.Crossbalance.Onboarding.SyncContacts.title, handler: { [weak self] in
            self?.primaryButtonTapped()
        }))
        button.setStyle(.largePrimary, sentiment: .none)
        return button
    }()

    private lazy var secondaryButton: LargeButtonView = {
        let button = LargeButtonView(viewModel: .init(title: L10n.Crossbalance.Onboarding.LearnMore.title, handler: { [weak self] in
            self?.secondaryButtonTapped()
        }))
        button.setStyle(.largeSecondaryNeutral, sentiment: .none)
        button.isHidden = true
        button.alpha = 0.0
        return button
    }()
}

extension FindFriendsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let prevPage = pageIndicator.currentPage
        let pageNumber = getPageNumberFrom(scrollView)
        if prevPage != pageNumber {
            pageUpdate(pageNumber)
        }
    }

    private func getPageNumberFrom(_ scrollView: UIScrollView) -> Int {
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = scrollView.contentOffset.x / pageWidth
        let page = fractionalPage.rounded(.toNearestOrAwayFromZero)
        return Int(page)
    }
}
