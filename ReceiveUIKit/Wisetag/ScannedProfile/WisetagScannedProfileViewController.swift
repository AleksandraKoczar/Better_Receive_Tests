import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWUI

// sourcery: AutoMockable
protocol WisetagScannedProfileView: AnyObject {
    var bottomSheetContent: UIViewController { get }
    func configure(with viewModel: WisetagScannedProfileViewModel)
    func configureError(with viewModel: ErrorViewModel)
}

final class WisetagScannedProfileViewController: BottomSheetViewController {
    private let presenter: WisetagScannedProfilePresenter

    // MARK: - Subviews

    private lazy var headerView = WisetagScannedProfileHeaderView()
    private lazy var footerView = WisetagScannedProfileFooterView()

    // MARK: - Life cycle

    init(presenter: WisetagScannedProfilePresenter) {
        self.presenter = presenter
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrangedSubviews = [
            headerView,
            footerView,
        ]
        stackView.spacing = theme.spacing.vertical.value24
        presenter.start(with: self)
    }
}

extension WisetagScannedProfileViewController: WisetagScannedProfileView {
    var bottomSheetContent: UIViewController { self }

    func configure(with viewModel: WisetagScannedProfileViewModel) {
        arrangedSubviews = [
            headerView,
            footerView,
        ]
        if let header = viewModel.header {
            headerView.isHidden = false
            headerView.configure(with: header)
        } else {
            headerView.isHidden = true
        }
        footerView.configure(with: viewModel.footer)
        updatePreferredContentSize()
    }

    func configureError(with viewModel: ErrorViewModel) {
        configureWithError(viewModel: viewModel)
    }
}
