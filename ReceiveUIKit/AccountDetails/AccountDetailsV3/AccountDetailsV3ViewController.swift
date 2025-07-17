import AnalyticsKit
import ApiKit
import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import WiseCore

// sourcery: AutoMockable
// sourcery: baseClass = "LoadingPresentableMock"
protocol AccountDetailsV3View: AnyObject, LoadingPresentable {
    var activeView: UIView { get }
    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate { get }
    func configure(with model: AccountDetailsV3)
    func configureNavigationBar(with model: AccountDetailsV3CurrencySelectorViewModel)
    func configureWithError(with errorViewModel: ErrorViewModel)
    func showErrorAlert(title: String, message: String)
    func showConfirmation(message: String)
    func generateHapticFeedback()
    func showHud()
    func hideHud()
}

final class AccountDetailsV3ViewController: LCEViewController, HasPostStandardDismissAction {
    private let presenter: AccountDetailsV3Presenter

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(
        arrangedSubviews: [],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault
    )

    private lazy var currencySelectorView: AccountDetailsV3CurrencySelectorView = {
        let view = AccountDetailsV3CurrencySelectorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var accountDetailsViewV3 = AccountDetailsV3ContainerView().with {
        $0.delegate = presenter.viewActionDelegate
    }

    private lazy var avatarView = AvatarView().with {
        $0.setStyle(.size40)
    }

    init(
        presenter: AccountDetailsV3Presenter
    ) {
        self.presenter = presenter
        super.init {
            presenter.refresh()
        }
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

extension AccountDetailsV3ViewController: AccountDetailsV3View {
    var activeView: UIView {
        view
    }

    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        self
    }

    func configure(with model: AccountDetailsV3) {
        tw_contentUnavailableConfiguration = nil
        stackView.removeAllArrangedSubviews()
        stackView.addArrangedSubview(accountDetailsViewV3)
        accountDetailsViewV3.configure(with: model)
    }

    func configureNavigationBar(with model: AccountDetailsV3CurrencySelectorViewModel) {
        currencySelectorView.configure(with: model)

        if let flag = makeFlagImage(currencyString: model.currency.value) {
            avatarView.configure(
                with: AvatarViewModel.image(flag)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarView)
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        navigationItem.titleView = currencySelectorView
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }

    func showConfirmation(message: String) {
        let configuration = SnackBarConfiguration(
            message: message
        )
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }

    func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension AccountDetailsV3ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
    ) -> UIViewController {
        self
    }
}

// MARK: - UI Helpers

private extension AccountDetailsV3ViewController {
    func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.edgesWithTopSafeArea)
    }

    func makeFlagImage(currencyString: String) -> UIImage? {
        guard let urn = try? URN("urn:wise:currencies:\(currencyString):image"),
              let image = FlagFactory.flag(urn: urn) else {
            return nil
        }
        return image
    }
}
