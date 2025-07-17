import Neptune
import TransferResources
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol PaymentRequestDetailView: AnyObject {
    var documentDelegate: UIDocumentInteractionControllerDelegate { get }
    var sourceView: UIView { get }
    func configure(with viewModel: PaymentRequestDetailViewModel)
    func showHud()
    func hideHud()
    func showSnackBar(message: String)
    func showShareOptions(viewModel: PaymentRequestDetailShareOptionsViewModel)
    func showPaymentMethodSummaries(viewModel: PaymentRequestDetailPaymentMethodsViewModel)
    func showDismissableAlert(title: String, message: String)
    func showAlert(title: String, message: String, leftAction: AlertAction, rightAction: AlertAction)
}

final class PaymentRequestDetailViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: PaymentRequestDetailPresenter
    var sourceView: UIView { view }

    // MARK: - Subviews

    private let iconView = AvatarView()

    private let headerLabel = LargeTitleView().with {
        $0.padding = .horizontal(.defaultMargin)
        $0.setStyle(.screen.centered)
    }

    private lazy var headerView = UIStackView(
        arrangedSubviews: [
            iconView,
            headerLabel,
        ],
        axis: .vertical,
        alignment: .center
    )

    private let sectionsView = UIStackView(
        axis: .vertical
    )
    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            headerView,
            sectionsView,
        ],
        axis: .vertical
    )

    private lazy var footerView = FooterView(
        configuration: .simple(button: .negative)
    )

    private lazy var scrollView = UIScrollView(contentView: stackView)

    // MARK: - Life cycle

    init(presenter: PaymentRequestDetailPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    // MARK: - Helpers

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)

        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        scrollView.constrainToSuperview(.contentArea)
    }

    private func configureSections(with viewModels: [PaymentRequestDetailViewModel.SectionViewModel]) {
        sectionsView.removeAllArrangedSubviews()
        let sectionViews = viewModels.map { sectionViewModel in
            let sectionView = SectionView<SectionHeaderView, EmptyContentView>()
            sectionView.headerView.configure(with: sectionViewModel.header)
            let itemViews = sectionViewModel.items.map { itemViewModel -> UIView in
                switch itemViewModel {
                case let .listItem(listItemViewModel):
                    let listItemView = LegacyStackListItemView(viewModel: listItemViewModel)
                    listItemView.setStyle(LegacyListItemViewStyle(buttonStyle: .smallSecondaryNeutral))
                    return listItemView
                case let .optionItem(optionItemViewModel):
                    let optionView = StackNavigationOptionView()
                    optionView.configure(with: optionItemViewModel.option)
                    optionView.onTap = optionItemViewModel.onTap
                    return optionView
                }
            }
            sectionView.contentView.addArrangedSubviews(itemViews)
            return sectionView
        }
        sectionsView.addArrangedSubviews(sectionViews)
    }

    private func configureFooter(with viewModel: PaymentRequestDetailViewModel.FooterViewModel?) {
        footerView.removeFromSuperview()

        guard let viewModel else {
            return
        }

        var configuration: any FooterViewConfiguration {
            switch viewModel.configuration {
            case .positiveOnly:
                .simple(button: .secondary)
            case .negativeOnly:
                .simple(button: .negative)
            case .positiveAndNegative:
                .extended(
                    primaryView: .secondary,
                    secondaryView: .negative
                )
            }
        }

        footerView.setConfiguration(configuration, animated: false)
        footerView.primaryViewModel = .init(viewModel.primaryAction)
        footerView.secondaryViewModel = .init(viewModel.secondaryAction)
        view.addSubview(footerView)
    }
}

// MARK: - PaymentRequestDetailView

extension PaymentRequestDetailViewController: PaymentRequestDetailView {
    func configure(with viewModel: PaymentRequestDetailViewModel) {
        iconView.configure(with: viewModel.header.icon)
        iconView.setStyle(viewModel.header.iconStyle)
        headerLabel.configure(
            with: LargeTitleViewModel(
                title: viewModel.header.title,
                description: viewModel.header.subtitle
            )
        )
        configureSections(with: viewModel.sections)
        configureFooter(with: viewModel.footer)
    }

    func showSnackBar(message: String) {
        let configuration = SnackBarConfiguration(message: message)
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: sourceView))
    }

    func showShareOptions(viewModel: PaymentRequestDetailShareOptionsViewModel) {
        presentNavigationOptionsSheet(
            items: viewModel.options,
            handler: viewModel.handler
        )
    }

    func showPaymentMethodSummaries(viewModel: PaymentRequestDetailPaymentMethodsViewModel) {
        presentSummariesSheet(
            title: viewModel.title,
            summaries: viewModel.summaries
        )
    }
}

// MARK: - HasPreDismissAction

extension PaymentRequestDetailViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: DismissActionType) {
        if type == .modalDismissal {
            presenter.dismiss()
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension PaymentRequestDetailViewController: UIDocumentInteractionControllerDelegate {
    var documentDelegate: UIDocumentInteractionControllerDelegate {
        self
    }

    func documentInteractionControllerViewControllerForPreview(_ previewController: UIDocumentInteractionController) -> UIViewController {
        self
    }
}
