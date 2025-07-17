import LoggingKit
import TWUI

// sourcery: AutoMockable
protocol AccountDetailsTipsView: AnyObject {
    func configure(with viewModel: UpsellViewModel)
    func showHud()
    func hideHud()
    func showErrorAlert(title: String, message: String)
}

final class AccountDetailsTipsViewController: UpsellViewController, AccountDetailsTipsView {
    private let presenter: AccountDetailsTipsPresenter

    // MARK: - Initializers

    init(presenter: AccountDetailsTipsPresenter) {
        self.presenter = presenter
        super.init()
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "AccountDetailsTipsView"
        Task {
            await presenter.start(with: self)
        }
    }
}
