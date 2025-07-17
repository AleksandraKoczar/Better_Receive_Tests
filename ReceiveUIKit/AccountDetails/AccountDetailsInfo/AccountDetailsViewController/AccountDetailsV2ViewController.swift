import AnalyticsKit
import ApiKit
import Foundation
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit

// sourcery: AutoMockable
protocol AccountDetailsInfoV2View: AnyObject {
    var activeView: UIView { get }
    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate { get }
    func showHud()
    func hideHud()
    func configure(with model: AccountDetailsV2ViewModel)
    func showConfirmation(message: String)

    func generateHapticFeedback()
    func showErrorAlert(title: String, message: String)
    func showError(
        title: String,
        message: String,
        leftAction: AlertAction,
        rightActionTitle: String
    )
}

final class AccountDetailsV2ViewController: AbstractViewController, HasPostStandardDismissAction {
    private let presenter: AccountDetailsV2Presenter

    private lazy var titleView = LargeTitleView(
        scrollObserver: scrollView.scrollObserver(),
        delegate: self,
        padding: .horizontal(theme.spacing.horizontal.componentDefault)
    )

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: UIEdgeInsets.zero
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.showsVerticalScrollIndicator = false
    }

    private lazy var stackView = UIStackView(
        axis: .vertical,
        spacing: .defaultSpacing
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var accountDetailsView = AccountDetailsV2View().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.delegate = presenter
    }

    init(
        presenter: AccountDetailsV2Presenter
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    func performPostStandardDismissAction(ofType type: DismissActionType) {
        presenter.dismiss()
    }
}

extension AccountDetailsV2ViewController: AccountDetailsInfoV2View {
    var activeView: UIView {
        view
    }

    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        self
    }

    func configure(with viewModel: AccountDetailsV2ViewModel) {
        stackView.removeAllArrangedSubviews()
        stackView.addArrangedSubviews(titleView)

        stackView.addArrangedSubview(accountDetailsView)
        titleView.configure(
            with: viewModel.title
        )

        accountDetailsView.configure(with: viewModel)

        if viewModel.isExploreEnabled {
            let button = SmallButtonView(viewModel: .init(title: L10n.Balance.Details.AccountDetails.Explore.title, handler: { [weak self] in
                self?.presenter.showExplore()
            }), style: .smallSecondaryNeutral)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    }

    func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func showError(
        title: String,
        message: String,
        leftAction: AlertAction,
        rightActionTitle: String
    ) {
        showAlert(
            title: title,
            message: message,
            leftAction: leftAction,
            rightAction: AlertAction(
                message: rightActionTitle,
                action: { [weak self] in
                    self?.dismiss(animated: UIView.shouldAnimate)
                }
            )
        )
    }

    func showConfirmation(message: String) {
        let configuration = SnackBarConfiguration(
            message: message
        )
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension AccountDetailsV2ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
    ) -> UIViewController {
        self
    }
}

// MARK: - UI Helpers

private extension AccountDetailsV2ViewController {
    func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
    }
}
