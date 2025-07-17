import LoggingKit
import Neptune
import SwiftUI
import TransferResources
import TWUI
import UIKit

// sourcery: AutoMockable
protocol PayWithWiseView: AnyObject {
    var documentDelegate: UIDocumentInteractionControllerDelegate { get }
    var presentationRootViewController: UIViewController { get }

    func configure(viewModel: PayWithWiseViewModel)
    func updateTitle(viewModel: PayWithWiseHeaderView.ViewModel)
    func showErrorAlert(title: String, message: String)
    func showHud()
    func hideHud()
}

final class PayWithWiseViewController: AbstractViewController {
    // MARK: - Views

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var titleView = PayWithWiseHeaderView()

    private lazy var stackView = UIStackView(
        axis: .vertical
    )

    private lazy var breakdownItemsStackView = UIStackView(
        axis: .vertical
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(.defaultMargin)
    }

    private lazy var detailsBarButtonItem = UIBarButtonItem(customView: detailsActionButton)

    private lazy var detailsActionButton = SmallButtonView(
        viewModel: .init(
            title: L10n.PayWithWise.Payment.ViewDetails.title,
            handler: { [weak self] in
                self?.presenter.showDetails()
            }
        ),
        style: .smallSecondaryNeutral,
        sentiment: .neutral
    )

    private var footerView: FooterView?

    // MARK: Properties

    private let presenter: PayWithWisePresenter
    private let breakdownViewFactory: BreakdownViewFactory

    // MARK: Lifecycle

    init(
        presenter: PayWithWisePresenter,
        breakdownViewFactory: BreakdownViewFactory
    ) {
        self.presenter = presenter
        self.breakdownViewFactory = breakdownViewFactory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.start(with: self)
    }
}

// MARK: - PayWithWiseView

extension PayWithWiseViewController: PayWithWiseView {
    var documentDelegate: UIDocumentInteractionControllerDelegate {
        self
    }

    var presentationRootViewController: UIViewController {
        self
    }

    func configure(viewModel: PayWithWiseViewModel) {
        switch viewModel {
        case let .loaded(loadedVm):
            configureLoaded(viewModel: loadedVm)
        case let .empty(emptyViewModel):
            configureEmpty(viewModel: emptyViewModel)
        }
    }

    func updateTitle(viewModel: PayWithWiseHeaderView.ViewModel) {
        titleView.configure(with: viewModel)
    }
}

// MARK: - HasPostStandardDismissAction

extension PayWithWiseViewController: HasPostStandardDismissAction {
    func performPostStandardDismissAction(ofType type: DismissActionType) {
        if type == .modalDismissal {
            presenter.dismiss()
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension PayWithWiseViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ previewController: UIDocumentInteractionController) -> UIViewController {
        self
    }
}

// MARK: - UI Helpers

private extension PayWithWiseViewController {
    func setupView() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    func addPaymentSection(viewModel: PayWithWiseViewModel.Section?) {
        guard let viewModel else { return }
        let header = Self.makeSectionHeader(viewModel: viewModel.header)
        stackView.addArrangedSubview(header)

        stackView.addArrangedSubviews(
            viewModel.sectionOptions
                .map { StackNavigationOptionView(viewModel: $0.option, onTap: $0.action) }
        )
    }

    static func makeSectionHeader(
        viewModel: SectionHeaderViewModel
    ) -> StackSectionHeaderView {
        let view = StackSectionHeaderView()
        view.configure(with: viewModel)
        return view
    }

    func configureLoaded(viewModel: PayWithWiseViewModel.Loaded) {
        scrollView.isHidden = false
        stackView.removeAllArrangedSubviews()
        tw_contentUnavailableConfiguration = nil

        navigationItem.rightBarButtonItem = viewModel.shouldHideDetailsButton ? nil : detailsBarButtonItem

        titleView.configure(with: viewModel.header)
        stackView.addArrangedSubview(titleView)

        addPaymentSection(viewModel: viewModel.paymentSection)

        breakdownItemsStackView.removeAllArrangedSubviews()
        if viewModel.breakdownItems.isNonEmpty {
            let breakdownView = breakdownViewFactory.make(
                feeBreakdown: viewModel.breakdownItems
            )

            breakdownItemsStackView.addArrangedSubview(
                SwiftUIHostingController<AnyView>(
                    content: { breakdownView }
                ).view
            )
            stackView.addArrangedSubview(breakdownItemsStackView)
        }

        if let alert = viewModel.inlineAlert {
            let alertView = StackInlineAlertView(viewModel: alert.viewModel)
            alertView.setStyle(alert.style)
            stackView.addArrangedSubviews([
                .spacer(theme.spacing.vertical.value24),
                alertView,
            ])
        }

        func getStyleForPrimary(style: PayWithWiseFooterViewModel.FirstButtonConfig.PrimaryButtonStyle) -> FooterPrimaryViewConfiguration {
            switch style {
            case .primary:
                .primary
            case .secondary:
                .secondary
            case .secondaryNeutral:
                .secondary
            case .negative:
                .negative
            }
        }

        func getStyleForSecondary(style: PayWithWiseFooterViewModel.SecondButtonConfig.SecondaryButtonStyle?) -> FooterSecondaryViewConfiguration? {
            switch style {
            case .secondary:
                .secondary
            case .secondaryNeutral:
                .secondaryNeutral
            case .negative:
                .negative
            case .tertiary:
                .tertiary
            case .none:
                nil
            }
        }

        footerView?.removeFromSuperview()
        if let footer = viewModel.footer {
            let footerView = FooterView(
                configuration: .extended(
                    primaryView: getStyleForPrimary(style: footer.firstButton.style),
                    secondaryView: getStyleForSecondary(style: footer.secondButton?.style) ?? .secondary,
                    topAccessoryView: nil,
                    bottomAccessoryView: nil,
                    separator: .solid(),
                    separatorHidden: .always,
                    hideTopAccessoryWhenKeyboardIsVisible: false
                )
            )

            footerView.primaryViewModel = LargeButtonView.ViewModel(
                title: footer.firstButton.title,
                isEnabled: footer.firstButton.isEnabled,
                handler: footer.firstButton.action
            )

            if let secondButton = footer.secondButton {
                footerView.secondaryViewModel = LargeButtonView.ViewModel(
                    title: secondButton.title,
                    isEnabled: secondButton.isEnabled,
                    handler: secondButton.action
                )
            }

            self.footerView = footerView
            view.addSubview(footerView)
        }
    }

    func configureEmpty(viewModel: PayWithWiseViewModel.Empty) {
        navigationItem.rightBarButtonItem = nil
        footerView?.removeFromSuperview()
        scrollView.isHidden = true

        let emptyViewModel = EmptyViewModel(
            illustrationConfiguration: IllustrationViewConfiguration(asset: .image(viewModel.image)),
            title: viewModel.title,
            message: .text(viewModel.message),
            primaryButton: .primary,
            secondaryButton: nil,
            primaryViewModel: .init(viewModel.buttonAction),
            secondaryViewModel: nil
        )

        tw_contentUnavailableConfiguration = .empty(emptyViewModel)
    }
}
