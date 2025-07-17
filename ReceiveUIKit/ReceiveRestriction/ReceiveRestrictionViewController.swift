import Foundation
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWUI
import UIKit

// sourcery: AutoMockable
protocol ReceiveRestrictionView: AnyObject {
    func configure(viewModel: ReceiveRestrictionViewModel)
    func showHud()
    func hideHud()
    func showErrorState(title: String, message: String)
}

final class ReceiveRestrictionViewController: AbstractViewController, OptsIntoAutoBackButton {
    private lazy var scrollView = UIScrollView(
        contentView: stackView
    ).with {
        $0.showsVerticalScrollIndicator = false
    }

    private lazy var stackView = UIStackView(
        axis: .vertical,
        spacing: 0
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let illustrationView = IllustrationView()
    private lazy var titleLabel = StackLabel().with {
        $0.numberOfLines = 0
        $0.setStyle(LabelStyle.screenTitle.centered)
        $0.padding = .horizontal(theme.spacing.horizontal.screen)
    }

    private lazy var bodyLabel = StackContainerView<MarkdownLabel>(frame: .zero).with {
        $0.setStyle(LabelStyle.largeBody.centered)
        $0.setSeparatorHidden(true)
        $0.numberOfLines = 0
        $0.linkActionHandler = { [weak self] uriString in
            self?.presenter.handleURI(string: uriString)
        }
        $0.padding = .horizontal(theme.spacing.horizontal.screen)
    }

    private let presenter: ReceiveRestrictionPresenter

    init(presenter: ReceiveRestrictionPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        presenter.start(view: self)
    }
}

extension ReceiveRestrictionViewController: ReceiveRestrictionView {
    func configure(viewModel: ReceiveRestrictionViewModel) {
        tw_contentUnavailableConfiguration = nil
        stackView.removeAllArrangedSubviews()

        illustrationView.configure(with: viewModel.illustration)
        titleLabel.configure(with: viewModel.title)
        bodyLabel.markdownText = viewModel.body

        stackView.addArrangedSubviews([
            illustrationView,
            titleLabel,
            .spacer(theme.spacing.vertical.componentDefault),
            bodyLabel,
        ])

        if let alert = viewModel.alert {
            let alertView = StackInlineAlertView(viewModel: alert.viewModel)
            alertView.padding = .horizontal(theme.spacing.horizontal.screen)
            alertView.setStyle(alert.style)
            stackView.addArrangedSubviews([
                .spacer(theme.spacing.vertical.betweenSections),
                alertView,
            ])
        }

        let sectionViews = makeSectionViews(sections: viewModel.sections)
        if sectionViews.isNonEmpty {
            stackView.addArrangedSubview(
                .spacer(theme.spacing.vertical.componentDefault)
            )
            stackView.addArrangedSubviews(
                sectionViews
            )
        }

        addFooter(viewModel.footers)
    }

    func showErrorState(title: String, message: String) {
        tw_contentUnavailableConfiguration = .error(
            ErrorViewModel(
                title: title,
                message: .text(message),
                primaryViewModel: .init(
                    title: L10n.Success.Screen.Ok.title,
                    handler: { [weak self] in
                        self?.presenter.dismiss()
                    }
                )
            )
        )
    }
}

// MARK: - View Helpers

private extension ReceiveRestrictionViewController {
    func setupSubviews() {
        view.addSubviewUsingAutoLayout(scrollView)
        scrollView.constrainToSuperview(.contentArea)
    }

    func makeSectionViews(sections: [ReceiveRestriction.Section]) -> [UIView] {
        func makeHeaderView(
            viewModel: ReceiveRestriction.Section.Header
        ) -> StackSectionHeaderView {
            let headerView = StackSectionHeaderView()
            headerView.padding = .horizontal(theme.spacing.horizontal.screen)

            headerView.configure(
                with: SectionHeaderViewModel(
                    title: viewModel.title,
                    action: {
                        guard let action = viewModel.action else {
                            return nil
                        }
                        return Action(
                            title: action.label,
                            handler: { [weak self] in
                                self?.presenter.handleURI(
                                    string: action.uri
                                )
                            }
                        )
                    }()
                )
            )
            return headerView
        }
        let joinedSections = sections
            .lazy
            .map { section in
                switch section {
                case let .instruction(instructionSection):
                    let headerView = makeHeaderView(viewModel: instructionSection.header)
                    let instructions = instructionSection.instructions
                        .map { instruction in
                            self.makeInstructionView(instruction)
                        }
                    return [
                        headerView,
                        UIView.spacer(self.theme.spacing.vertical.betweenText),
                    ].appending(contentsOf: instructions)

                case let .summary(summarySection):
                    let headerView = makeHeaderView(viewModel: summarySection.header)
                    let summaries = summarySection.summaries.map { summary in
                        self.makeSummaryView(summary)
                    }
                    return [
                        headerView,
                        .spacer(self.theme.spacing.vertical.betweenText),
                    ].appending(contentsOf: summaries)
                }
            }
            .joined(
                separator: [
                    UIView.spacer(
                        theme.spacing.vertical.betweenSections
                    ),
                ]
            )
        return Array(joinedSections)
    }

    func makeInstructionView(
        _ instruction: ReceiveRestriction.Section.Instruction
    ) -> StackInstructionView {
        let instructionView = StackInstructionView(
            viewModel: .markup(instruction.content)
        )
        let style: InstructionViewStyle =
            switch instruction.type {
            case .positive: .positive
            case .negative: .negative
            }
        instructionView.setStyle(style)
        instructionView.padding = .init(
            vertical: theme.spacing.vertical.betweenText,
            horizontal: theme.spacing.horizontal.screen
        )
        return instructionView
    }

    func makeSummaryView(_ summary: ReceiveRestriction.Section.Summary) -> StackSummaryView {
        let summaryView = StackSummaryView(
            viewModel: SummaryView.ViewModel(
                title: summary.content,
                icon: summary.iconImage
            )
        )
        summaryView.padding = .init(
            vertical: theme.spacing.vertical.betweenText,
            horizontal: theme.spacing.horizontal.screen
        )
        return summaryView
    }

    func addFooter(_ footers: [ReceiveRestrictionViewModel.Footer]) {
        func makeAction(for footer: ReceiveRestrictionViewModel.Footer) -> Action {
            Action(
                title: footer.label,
                handler: { [weak self] in
                    self?.presenter.handleFooterAction(type: footer.type)
                }
            )
        }

        guard footers.isNonEmpty else { return }
        if footers.count == 1,
           let footer = footers.first {
            let footerView =
                switch footer.type {
                case .dismiss:
                    FooterView(configuration: .extended(
                        primaryView: .primary,
                        separatorHidden: .never
                    )).with {
                        $0.primaryViewModel = .init(makeAction(for: footer))
                    }
                case .link:
                    FooterView(configuration: .extended(
                        secondaryView: .tertiary,
                        separatorHidden: .never
                    )).with {
                        $0.secondaryViewModel = .init(makeAction(for: footer))
                    }
                }
            view.addSubview(footerView)
        } else if footers.count == 2,
                  let firstFooter = footers.first,
                  let secondFooter = footers.last {
            let footerView =
                switch secondFooter.type {
                case .dismiss:
                    FooterView(configuration: .extended(
                        primaryView: .primary,
                        secondaryView: .secondaryNeutral,
                        separatorHidden: .never
                    ))
                case .link:
                    FooterView(configuration: .extended(
                        primaryView: .primary,
                        secondaryView: .tertiary,
                        separatorHidden: .never
                    ))
                }
            footerView.primaryViewModel = .init(makeAction(for: firstFooter))
            footerView.secondaryViewModel = .init(makeAction(for: secondFooter))
            view.addSubview(footerView)
        }
    }
}

extension ReceiveRestrictionViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: DismissActionType) {
        presenter.dismiss()
    }
}
