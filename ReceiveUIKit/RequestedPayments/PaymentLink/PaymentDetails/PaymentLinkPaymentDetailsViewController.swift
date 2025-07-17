import TWUI
import UIKit

// sourcery: AutoMockable
protocol PaymentLinkPaymentDetailsView: AnyObject {
    func configure(with viewModel: PaymentLinkPaymentDetailsViewModel)
    func showHud()
    func hideHud()
    func showDismissableAlert(title: String, message: String)
}

final class PaymentLinkPaymentDetailsViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: PaymentLinkPaymentDetailsPresenter

    // MARK: - Subviews

    private lazy var titleView = LargeTitleView().with {
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private let sectionsView = UIStackView(
        axis: .vertical
    )

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            titleView,
            sectionsView,
        ],
        axis: .vertical
    )

    private lazy var scrollView = UIScrollView(contentView: stackView)

    // MARK: - Life cycle

    init(presenter: PaymentLinkPaymentDetailsPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }
}

// MARK: - Helpers

private extension PaymentLinkPaymentDetailsViewController {
    func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    func configureSections(with viewModels: [PaymentLinkPaymentDetailsViewModel.Section]) {
        sectionsView.removeAllArrangedSubviews()
        let sectionViews = viewModels.map { sectionViewModel in
            let sectionView = SectionView<SectionHeaderView, EmptyContentView>()
            sectionView.headerView.configure(
                with: SectionHeaderViewModel(title: sectionViewModel.title)
            )
            let itemViews = sectionViewModel.items.map { itemViewModel -> UIView in
                switch itemViewModel {
                case let .listItem(listItemViewModel):
                    return LegacyStackListItemView(viewModel: listItemViewModel)
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
}

// MARK: - PaymentLinkPaymentDetailsView

extension PaymentLinkPaymentDetailsViewController: PaymentLinkPaymentDetailsView {
    func configure(with viewModel: PaymentLinkPaymentDetailsViewModel) {
        titleView.configure(with: viewModel.title)
        configureSections(with: viewModel.sections)
    }
}
