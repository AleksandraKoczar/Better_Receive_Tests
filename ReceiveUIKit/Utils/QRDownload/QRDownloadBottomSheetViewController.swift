import LoggingKit
import TWUI
import UIKit

// sourcery: AutoMockable
protocol QRDownloadView: AnyObject {
    func configure(with viewModel: QRDownloadViewModel)
}

final class QRDownloadBottomSheetViewController: BottomSheetViewController {
    private let presenter: QRDownloadPresenter

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

    private let saveToCameraOptionView = StackNavigationOptionView()
    private let saveToFilesOptionView = StackNavigationOptionView()

    // MARK: - Lifecycle

    init(presenter: QRDownloadPresenter) {
        self.presenter = presenter
        super.init(arrangedSubviews: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrangedSubviews = [
            titleView,
            subtitleLabel,
            saveToCameraOptionView,
            saveToFilesOptionView,
        ]
        stackView.spacing = theme.spacing.vertical.betweenText
        stackView.layoutMargins = UIEdgeInsets(
            top: .zero,
            left: .zero,
            bottom: theme.spacing.vertical.value24,
            right: .zero
        )
        presenter.start(with: self)
    }
}

extension QRDownloadBottomSheetViewController: QRDownloadView {
    func configure(with viewModel: QRDownloadViewModel) {
        titleView.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)
        saveToCameraOptionView.configure(with: viewModel.cameraDownloadOption.viewModel)
        saveToCameraOptionView.onTap = viewModel.cameraDownloadOption.onTap
        saveToFilesOptionView.configure(with: viewModel.fileDownloadOption.viewModel)
        saveToFilesOptionView.onTap = viewModel.fileDownloadOption.onTap
    }
}
