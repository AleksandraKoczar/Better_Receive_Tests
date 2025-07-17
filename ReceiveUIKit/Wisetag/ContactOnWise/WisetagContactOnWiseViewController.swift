import LoggingKit
import Neptune
import TWUI
import UIKit

// sourcery: AutoMockable
protocol WisetagContactOnWiseView: AnyObject {
    func configure(with viewModel: WisetagContactOnWiseViewModel)
}

final class WisetagContactOnWiseViewController: BottomSheetViewController {
    private let presenter: WisetagContactOnWisePresenter

    // MARK: - Subview

    private lazy var titleView = StackLabel().with {
        $0.setStyle(\.sectionTitle)
        $0.padding = .horizontal(.defaultMargin)
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(\.largeBody)
        $0.textAlignment = .left
        $0.padding = .horizontal(.defaultMargin)
    }

    // MARK: - Subviews

    private let wisetagOptionView = StackSwitchOptionView()

    private let inlineAlertView = StackInlineAlertView()

    // MARK: - Lifecycle

    init(presenter: WisetagContactOnWisePresenter) {
        self.presenter = presenter
        super.init(arrangedSubviews: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrangedSubviews = [titleView, subtitleLabel, inlineAlertView, wisetagOptionView]
        stackView.spacing = theme.spacing.vertical.value12
        presenter.start(with: self)
    }
}

// MARK: - WisetagContactOnWiseView

extension WisetagContactOnWiseViewController: WisetagContactOnWiseView {
    func configure(with viewModel: WisetagContactOnWiseViewModel) {
        titleView.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)
        wisetagOptionView.configure(with: viewModel.wisetagOption.viewModel)
        wisetagOptionView.onToggle = viewModel.wisetagOption.onToggle
        footerConfiguration = .simple(separatorHidden: .always)
        primaryAction = .init(viewModel.action)
        configureAlert(with: viewModel.inlineAlert)
    }

    private func configureAlert(with alert: WisetagContactOnWiseViewModel.Alert?) {
        guard let alert else {
            stackView.hideArrangedSubviews([inlineAlertView])
            return
        }

        inlineAlertView.configure(with: alert.viewModel)
        inlineAlertView.setStyle(alert.style)
        stackView.showArrangedSubviews([inlineAlertView])
    }
}
