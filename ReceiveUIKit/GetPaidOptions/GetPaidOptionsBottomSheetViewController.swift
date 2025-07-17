import AnalyticsKit
import Foundation
import Neptune
import TransferResources
import TWFoundation
import TWUI
import WiseCore

enum GetPaidOption {
    case requestMoney
    case createInvoice
}

// sourcery: AutoMockable
protocol GetPaidOptionsRoutingDelegate: AnyObject {
    func didSelectGetPaidOption(_ option: GetPaidOption)
}

final class GetPaidOptionsBottomSheetViewController: BottomSheetViewController {
    private let requestMoneyNavigationView = StackNavigationOptionView()
    private let createInvoiceNavigationView = StackNavigationOptionView()
    private weak var delegate: GetPaidOptionsRoutingDelegate?

    // MARK: - Lifecycle

    init(
        delegate: GetPaidOptionsRoutingDelegate?
    ) {
        self.delegate = delegate
        super.init(arrangedSubviews: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrangedSubviews = [
            createInvoiceNavigationView,
            requestMoneyNavigationView,
        ]
        stackView.spacing = theme.spacing.vertical.value12
        configureView()
    }
}

private extension GetPaidOptionsBottomSheetViewController {
    func configureView() {
        requestMoneyNavigationView.configure(with: .init(
            title: L10n.GetPaid.ShareLink.title,
            avatar: ._icon(Icons.link.image, badge: nil)
        ))
        requestMoneyNavigationView.onTap = { [weak self] in
            self?.delegate?.didSelectGetPaidOption(.requestMoney)
        }
        createInvoiceNavigationView.configure(with: .init(
            title: L10n.GetPaid.CreateInvoice.title,
            avatar: ._icon(Icons.document.image, badge: nil)
        ))
        createInvoiceNavigationView.onTap = { [weak self] in
            self?.delegate?.didSelectGetPaidOption(.createInvoice)
        }
    }
}
