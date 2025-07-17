import LoggingKit
import Neptune
import SwiftUI
import TransferResources
import TWFoundation
import TWUI
import UIKit

// sourcery: AutoMockable
protocol QuickpayView: AnyObject {
    var traitCollection: UITraitCollection { get }
    func configure(with viewModel: QuickpayViewModel)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func showSnackbar(message: String)
    func updateNudge(_ nudge: NudgeViewModel?)
    func showHud()
    func hideHud()
}

final class QuickpayViewController: AbstractViewController, OptsIntoAutoBackButton, QuickpayView {
    private let presenter: QuickpayPresenter

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            headerView,
            qrCodeStackView,
            shareButtonStackView,
            nudgeView,
            subsectionLabel1,
            carouselStackView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value32
    )

    private lazy var carouselStackView = UIStackView()

    let headerView = QuickpayHeaderView()

    let nudgeView = StackNudgeView()

    private lazy var qrCodeStackView = UIStackView()

    private lazy var subsectionLabel1 = StackLabel().with {
        $0.setStyle(\.subsectionTitle)
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var shareButtonStackView = UIStackView(
        axis: .horizontal
    ).with {
        $0.spacing = 0.0
        $0.alignment = .center
        $0.distribution = .fillEqually
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = .init(.init(
            horizontal: theme.spacing.horizontal.value32
        ))
    }

    private let footerView = FooterView()

    // MARK: - Lifecycle

    init(
        presenter: QuickpayPresenter
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "Quickpay management page"
        setupSubviews()
        presenter.start(with: self)
    }
}

// MARK: - QuickpayView

extension QuickpayViewController {
    func configure(with viewModel: QuickpayViewModel) {
        headerView.configure(with: viewModel)
        configureQRCodeView(viewModel: viewModel.qrCode)
        configureFooter(with: viewModel.footerAction)
        configureShareButtons(with: viewModel.circularButtons)
        configureRightBarButtonItems(with: viewModel.navigationBarButtons)
        subsectionLabel1.text = viewModel.subtitle
        configureCarousel(viewModel: viewModel)
        updateNudge(viewModel.nudge)
    }

    func updateNudge(_ nudge: NudgeViewModel?) {
        if let nudge {
            nudgeView.configure(with: nudge)
            nudgeView.isHidden = false
        } else {
            nudgeView.isHidden = true
        }
    }

    func resetView() {
        tw_contentUnavailableConfiguration = nil
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        resetView()
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func showSnackbar(message: String) {
        guard let view else { return }

        let configuration = SnackBarConfiguration(
            message: message
        )
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }
}

private extension QuickpayViewController {
    func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
    }

    func configureFooter(with action: Action?) {
        footerView.removeFromSuperview()
        if let action {
            footerView.primaryViewModel = .init(action)
            view.addSubview(footerView)
        }
    }

    func configureRightBarButtonItems(with viewModels: [QuickpayViewModel.ButtonViewModel]) {
        navigationItem.rightBarButtonItems = []
        navigationItem.rightBarButtonItems = viewModels.map { viewModel in
            let barButtonItem = UIBarButtonItem()
            barButtonItem.customView = IconButtonView(
                icon: viewModel.icon,
                discoverabilityTitle: "",
                style: .iconSecondaryNeutral(size: .size32),
                handler: viewModel.action
            )
            return barButtonItem
        }
    }

    private func configureShareButtons(with viewModels: [QuickpayViewModel.ButtonViewModel]) {
        shareButtonStackView.removeAllArrangedSubviews()
        let buttons = viewModels.map { viewModel in
            let button = CircularButton()
            button.setTitle(viewModel.title, for: .normal)
            button.setIcon(viewModel.icon, for: .normal)
            button.touchHandler = { viewModel.action() }
            return button
        }
        shareButtonStackView.addArrangedSubviews(buttons)
    }

    func configureQRCodeView(
        viewModel: WisetagQRCodeViewModel
    ) {
        qrCodeStackView.removeAllArrangedSubviews()
        let qrCodeView = WisetagQRCodeView(viewModel: viewModel)
        let controller = SwiftUIHostingController<WisetagQRCodeView>(
            content: { qrCodeView }
        )
        qrCodeStackView.addArrangedSubviews(controller.view)
        qrCodeStackView.alignment = .center
        qrCodeStackView.distribution = .fill
    }

    func configureCarousel(
        viewModel: QuickpayViewModel
    ) {
        carouselStackView.removeAllArrangedSubviews()

        let carouselViewModel = QuickPayCarouselViewModel(
            cards: viewModel.cardItems,
            onTap: viewModel.onCardTap
        )

        if #available(iOS 17.0, *) {
            let carouselView = CarouselView(
                items: carouselViewModel.cards,
                cardView: { item in
                    QuickpayCardContent(item: item)
                },
                onTap: carouselViewModel.onTap,
                cardStyle: .regular
            )

            let controller = SwiftUIHostingController<CarouselView>(
                content: { carouselView }
            )

            carouselStackView.addArrangedSubviews(controller.view)
            carouselStackView.alignment = .center
            carouselStackView.distribution = .fill
        } else {
            let carouselTabView = CarouselTabView(
                items: carouselViewModel.cards,
                cardView: { item in
                    QuickpayCardContent(item: item)
                },
                onTap: carouselViewModel.onTap,
                cardStyle: .regular
            )

            let controller = SwiftUIHostingController<CarouselTabView>(
                content: { carouselTabView }
            )

            carouselStackView.addArrangedSubviews(controller.view)
            carouselStackView.alignment = .center
            carouselStackView.distribution = .fill
        }
    }
}
