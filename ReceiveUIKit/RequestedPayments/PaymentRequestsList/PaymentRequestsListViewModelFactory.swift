import Combine
import ContactsKit
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentRequestsListViewModelDelegate: AnyObject {
    func segmentedControlSelected(at index: Int)
    func sortTapped()
    func fetchAvatarModel(
        urlString: String,
        badge: UIImage?,
        fallbackModel: ContactsKit.AvatarModel
    ) -> AnyPublisher<ContactsKit.AvatarModel, Never>
    func sortingOptionTapped(at index: Int)
    func applySortingAction()
    func createRequestPaymentTapped()
    func openSettingsTapped()
    func learnMoreTapped()
}

// sourcery: AutoMockable
protocol PaymentRequestsListViewModelFactory {
    func makeGlobalEmptyState(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel

    func make(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel

    func makeSectionViewModels(
        paymentRequestSummaryList: PaymentRequestSummaryList,
        groups: [PaymentRequestSummaries.Group],
        delegate: PaymentRequestsListViewModelDelegate
    ) -> [PaymentRequestsListViewModel.PaymentRequests.Section]

    func makeRadioOptionsViewModel(
        sortingState: PaymentRequestSummaryList.SortingState,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListRadioOptionsViewModel
}

struct PaymentRequestsListViewModelFactoryImpl: PaymentRequestsListViewModelFactory {
    func makeGlobalEmptyState(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        switch supportedPaymentRequestType {
        case .singleUseAndReusable:
            makeGlobalPaymentLinkEmptyState(delegate: delegate)
        case .singleUseOnly:
            makeGlobalPaymentRequestEmptyState(delegate: delegate)
        case .invoiceOnly:
            makeGlobalInvoiceEmptyState(delegate: delegate)
        }
    }

    func makeGlobalInvoiceEmptyState(
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        .emptyState(.init(
            illustration: .image(Illustrations.documents.image),
            title: L10n.PaymentRequest.List.Empty.Global.Invoice.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.Fast.description,
                    icon: Icons.documents.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.GlobalLocal.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.GlobalLocal.description,
                    icon: Icons.globe.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.Track.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.Track.description,
                    icon: Icons.payments.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.Invoice.createInvoice) {
                delegate.createRequestPaymentTapped()
            },
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {
                delegate.learnMoreTapped()
            }
        ))
    }

    func makeGlobalPaymentLinkEmptyState(
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        .emptyState(.init(
            illustration: .image(Illustrations.multiCurrency.image),
            title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.CreateSend.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.CreateSend.description,
                    icon: Icons.link.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.ReuseRepeat.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.ReuseRepeat.description,
                    icon: Icons.reload.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.Fast.description,
                    icon: Icons.lightningBolt.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.createPaymentLink) {
                delegate.createRequestPaymentTapped()
            },
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {
                delegate.learnMoreTapped()
            }
        ))
    }

    func makeGlobalPaymentRequestEmptyState(
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        .emptyState(.init(
            illustration: .image(Illustrations.multiCurrency.image),
            title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Easy.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Easy.description,
                    icon: Icons.requestReceive.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Customize.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Customize.description,
                    icon: Icons.list.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Fast.description,
                    icon: Icons.lightningBolt.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.requestPayment) {
                delegate.createRequestPaymentTapped()
            },
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {
                delegate.learnMoreTapped()
            }
        ))
    }

    func make(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        let chipSwitcher = makeSegmentedControlViewModel(
            supportedPaymentRequestType: supportedPaymentRequestType,
            profile: profile,
            paymentRequestSummaryList: paymentRequestSummaryList,
            delegate: delegate
        )
        let headerTitle = makeHeaderTitle(
            supportedPaymentRequestType: supportedPaymentRequestType
        )
        let header = PaymentRequestsListHeaderView.ViewModel(
            title: LargeTitleViewModel(title: headerTitle),
            segmentedControl: chipSwitcher
        )
        let isCreatePaymentRequestAvailable = profile.has(privilege: PaymentRequestPrivilege.create)
        return .paymentRequests(.init(
            navigationBarButtons: makeNavigationBarButtons(
                profile: profile,
                delegate: delegate
            ),
            header: header,
            content: makePaymentRequestSummariesContent(
                paymentRequestSummaryList: paymentRequestSummaryList,
                delegate: delegate
            ),
            isCreatePaymentRequestHidden: !isCreatePaymentRequestAvailable
        ))
    }

    func makeNavigationBarButtons(
        profile: Profile,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel] {
        switch profile.type {
        case .personal:
            [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                    title: L10n.PaymentRequest.List.Create.new,
                    icon: Icons.plus.image,
                    action: { [weak delegate] in
                        delegate?.createRequestPaymentTapped()
                    }
                ),
            ]
        case .business:
            [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                    title: nil,
                    icon: Icons.slider.image,
                    action: { [weak delegate] in
                        delegate?.openSettingsTapped()
                    }
                ),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                    title: L10n.PaymentRequest.List.Create.new,
                    icon: Icons.plus.image,
                    action: { [weak delegate] in
                        delegate?.createRequestPaymentTapped()
                    }
                ),
            ]
        }
    }

    func makeSectionViewModels(
        paymentRequestSummaryList: PaymentRequestSummaryList,
        groups: [PaymentRequestSummaries.Group],
        delegate: PaymentRequestsListViewModelDelegate
    ) -> [PaymentRequestsListViewModel.PaymentRequests.Section] {
        switch paymentRequestSummaryList.visibleState {
        case .upcoming:
            let sectionTitle = makeSortingSectionTitle(
                sortingState: paymentRequestSummaryList.upcoming.visibleState
            )
            let section = PaymentRequestsListViewModel.PaymentRequests.Section(
                id: sectionTitle,
                viewModel: SectionHeaderViewModel(
                    title: sectionTitle,
                    action: makeSortingSectionAction(delegate: delegate),
                    accessibilityHint: sectionTitle
                ),
                isSectionHeaderHidden: hasOnlyOneGroupWithOneSummary(in: groups),
                rows: groups
                    .flatMap(\.summaries)
                    .map { makeRowWithAvatarPublisher(summary: $0, delegate: delegate) }
            )
            return [section]
        case .unpaid:
            let sectionTitle = makeSortingSectionTitle(
                sortingState: paymentRequestSummaryList.unpaid.visibleState
            )
            let section = PaymentRequestsListViewModel.PaymentRequests.Section(
                id: sectionTitle,
                viewModel: SectionHeaderViewModel(
                    title: sectionTitle,
                    action: makeSortingSectionAction(delegate: delegate),
                    accessibilityHint: sectionTitle
                ),
                isSectionHeaderHidden: hasOnlyOneGroupWithOneSummary(in: groups),
                rows: groups
                    .flatMap(\.summaries)
                    .map { makeRowWithAvatarPublisher(summary: $0, delegate: delegate) }
            )
            return [section]
        case .paid,
             .inactive,
             .active,
             .past:
            return groups.map { group in
                PaymentRequestsListViewModel.PaymentRequests.Section(
                    id: group.id,
                    viewModel: SectionHeaderViewModel(
                        title: group.label,
                        accessibilityHint: group.label
                    ),
                    isSectionHeaderHidden: hasOnlyOneGroupWithOneSummary(in: groups),
                    rows: group.summaries.map { makeRowWithAvatarPublisher(summary: $0, delegate: delegate) }
                )
            }
        }
    }

    func makeRadioOptionsViewModel(
        sortingState: PaymentRequestSummaryList.SortingState,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListRadioOptionsViewModel {
        PaymentRequestsListRadioOptionsViewModel(
            title: L10n.PaymentRequest.List.Chip.Unpaid.RadioOptionsSheet.title,
            options: makeSortingRadioOptionViewModels(sortingState: sortingState),
            dismissOnSelection: false,
            action: makeApplySortingAction(delegate: delegate),
            handler: { [weak delegate] index, _ in
                delegate?.sortingOptionTapped(at: index)
            }
        )
    }
}

// MARK: - Header

private extension PaymentRequestsListViewModelFactoryImpl {
    func makeChips(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile
    ) -> [String] {
        switch supportedPaymentRequestType {
        case .singleUseOnly where profile.type == .personal:
            [
                L10n.PaymentRequest.List.Chip.unpaid,
                L10n.PaymentRequest.List.Chip.paid,
            ]
        case .singleUseOnly:
            [
                L10n.PaymentRequest.List.Chip.active,
                L10n.PaymentRequest.List.Chip.inactive,
            ]
        case .singleUseAndReusable:
            [
                L10n.PaymentRequest.List.Chip.active,
                L10n.PaymentRequest.List.Chip.inactive,
            ]
        case .invoiceOnly:
            [
                L10n.PaymentRequest.List.Chip.upcoming,
                L10n.PaymentRequest.List.Chip.past,
            ]
        }
    }

    func getSelectedChipIndex(
        paymentRequestSummaryList: PaymentRequestSummaryList
    ) -> Int {
        switch paymentRequestSummaryList.visibleState {
        case .unpaid,
             .active,
             .upcoming:
            0
        case .paid,
             .inactive,
             .past:
            1
        }
    }

    func makeSegmentedControlViewModel(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> SegmentedControlView.ViewModel {
        SegmentedControlView.ViewModel(segments: makeChips(
            supportedPaymentRequestType: supportedPaymentRequestType,
            profile: profile
        ), selectedIndex: getSelectedChipIndex(paymentRequestSummaryList: paymentRequestSummaryList)) { [weak delegate] index in
            delegate?.segmentedControlSelected(at: index)
        }
    }

    func makeHeaderTitle(
        supportedPaymentRequestType: SupportedPaymentRequestType
    ) -> String {
        switch supportedPaymentRequestType {
        case .singleUseOnly:
            L10n.PaymentRequest.List.title
        case .singleUseAndReusable:
            L10n.PaymentRequest.List.ReusableEnabled.title
        case .invoiceOnly:
            L10n.PaymentRequest.List.Invoices.title
        }
    }
}

// MARK: - Content and sections

private extension PaymentRequestsListViewModelFactoryImpl {
    private func getSummariesKeyPath(
        visibleState: PaymentRequestSummaryList.State
    ) -> KeyPath<PaymentRequestSummaryList, PaymentRequestSummaries> {
        switch visibleState {
        case .active:
            \.active
        case .inactive:
            \.inactive
        case .unpaid(.closestToExpiry):
            \.unpaid.closestToExpiry
        case .unpaid(.mostRecentlyRequested):
            \.unpaid.mostRecentlyRequested
        case .paid:
            \.paid
        case .upcoming(.closestToExpiry):
            \.upcoming.closestToExpiry
        case .upcoming(.mostRecentlyRequested):
            \.upcoming.mostRecentlyRequested
        case .past:
            \.past
        }
    }

    func makeEmptyStateViewModel(
        paymentRequestSummaryList: PaymentRequestSummaryList
    ) -> EmptyViewModel {
        let image: UIImage
        let message: String

        switch paymentRequestSummaryList.visibleState {
        case .active:
            image = Neptune.Illustrations.sandTimer.image
            message = L10n.PaymentRequest.List.Empty.active
        case .inactive:
            image = Neptune.Illustrations.sandTimer.image
            message = L10n.PaymentRequest.List.Empty.inactive
        case .unpaid,
             .upcoming:
            image = Neptune.Illustrations.sandTimer.image
            message = L10n.PaymentRequest.List.Empty.unpaid
        case .paid:
            image = Neptune.Illustrations.receive.image
            message = L10n.PaymentRequest.List.Empty.paid
        case .past:
            image = Neptune.Illustrations.receive.image
            message = L10n.PaymentRequest.List.Empty.past
        }

        return EmptyViewModel(
            illustrationConfiguration: .init(asset: .image(image)),
            message: .text(message)
        )
    }

    func makeSortingSectionTitle(
        sortingState: PaymentRequestSummaryList.SortingState
    ) -> String {
        switch sortingState {
        case .closestToExpiry:
            L10n.PaymentRequest.List.Chip.Unpaid.Section.Title.closestToExpiry
        case .mostRecentlyRequested:
            L10n.PaymentRequest.List.Chip.Unpaid.Section.Title.mostRecentlyRequested
        }
    }

    func makeSortingSectionAction(
        delegate: PaymentRequestsListViewModelDelegate
    ) -> Action {
        Action(
            title: L10n.PaymentRequest.List.Chip.Unpaid.Section.Action.sort,
            handler: { [weak delegate] in
                delegate?.sortTapped()
            }
        )
    }

    func hasOnlyOneGroupWithOneSummary(in groups: [PaymentRequestSummaries.Group]) -> Bool {
        if groups.count == 1,
           groups.first?.summaries.count == 1 {
            return true
        }
        return false
    }

    func makeIcon(from urnString: String) -> UIImage {
        guard let urn = try? URN(urnString),
              let image = IconFactory.icon(urn: urn) else {
            return Icons.fastFlag.image
        }
        return image
    }

    func makeBadge(
        from badge: PaymentRequestSummaries.Group.Summary.Badge?
    ) -> UIImage? {
        badge.map { badge in
            switch badge {
            case .warning:
                Icons.alert.image
            case .positive:
                Icons.check.image
            }
        }
    }

    func makeIconStyle(
        from badge: PaymentRequestSummaries.Group.Summary.Badge?
    ) -> AvatarViewStyle {
        guard let badge else {
            return .size48
        }
        return .size48.with {
            switch badge {
            case .warning:
                $0.badge = .warning()
            case .positive:
                $0.badge = .positive()
            }
        }
    }

    func makeRowForNoAvatar(
        summary: PaymentRequestSummaries.Group.Summary
    ) -> PaymentRequestsListViewModel.PaymentRequests.Section.Row {
        PaymentRequestsListViewModel.PaymentRequests.Section.Row(
            id: summary.id,
            title: summary.title,
            subtitle: summary.subtitle,
            avatarStyle: makeIconStyle(from: summary.badge),
            avatarPublisher: AvatarPublisher.image(
                avatarPublisher: .just(
                    AvatarModel.icon(
                        makeIcon(from: summary.icon),
                        badge: makeBadge(from: summary.badge)
                    )
                )
            )
        )
    }

    func makeRowForAvatar(
        urlString: String,
        summary: PaymentRequestSummaries.Group.Summary,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel.PaymentRequests.Section.Row {
        let fallbackModel = AvatarModel.icon(
            makeIcon(from: summary.icon),
            badge: makeBadge(from: summary.badge)
        )
        return PaymentRequestsListViewModel.PaymentRequests.Section.Row(
            id: summary.id,
            title: summary.title,
            subtitle: summary.subtitle,
            avatarStyle: makeIconStyle(from: summary.badge),
            avatarPublisher: AvatarPublisher.image(
                avatarPublisher: delegate.fetchAvatarModel(
                    urlString: urlString,
                    badge: makeBadge(from: summary.badge),
                    fallbackModel: fallbackModel
                )
            )
        )
    }

    func makeRowForInitials(
        value: String,
        summary: PaymentRequestSummaries.Group.Summary
    ) -> PaymentRequestsListViewModel.PaymentRequests.Section.Row {
        PaymentRequestsListViewModel.PaymentRequests.Section.Row(
            id: summary.id,
            title: summary.title,
            subtitle: summary.subtitle,
            avatarStyle: makeIconStyle(from: summary.badge),
            avatarPublisher: AvatarPublisher.initials(
                avatarPublisher: .just(
                    AvatarModel.initials(
                        Initials(value: value),
                        badge: makeBadge(from: summary.badge)
                    )
                ),
                gradientPublisher: .just(.none)
            )
        )
    }

    func makeRowWithAvatarPublisher(
        summary: PaymentRequestSummaries.Group.Summary,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel.PaymentRequests.Section.Row {
        guard let avatar = summary.avatar else {
            return makeRowForNoAvatar(summary: summary)
        }
        switch avatar {
        case let .avatar(urlString):
            return makeRowForAvatar(
                urlString: urlString,
                summary: summary,
                delegate: delegate
            )
        case let .initials(value):
            return makeRowForInitials(
                value: value,
                summary: summary
            )
        }
    }

    func makePaymentRequestSummariesContent(
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel.PaymentRequests.Content {
        let summariesKeyPath = getSummariesKeyPath(visibleState: paymentRequestSummaryList.visibleState)
        let summaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
        guard summaries.groups.isNonEmpty else {
            return .empty(
                makeEmptyStateViewModel(paymentRequestSummaryList: paymentRequestSummaryList)
            )
        }
        return .sections(
            makeSectionViewModels(
                paymentRequestSummaryList: paymentRequestSummaryList,
                groups: summaries.groups,
                delegate: delegate
            )
        )
    }
}

// MARK: - Raido options

private extension PaymentRequestsListViewModelFactoryImpl {
    func makeSortingRadioOptionViewModels(
        sortingState: PaymentRequestSummaryList.SortingState
    ) -> [RadioOptionViewModel] {
        [
            RadioOptionViewModel(
                model: OptionViewModel(title: L10n.PaymentRequest.List.Chip.Unpaid.Section.Title.closestToExpiry),
                isSelected: sortingState == .closestToExpiry
            ),
            RadioOptionViewModel(
                model: OptionViewModel(title: L10n.PaymentRequest.List.Chip.Unpaid.Section.Title.mostRecentlyRequested),
                isSelected: sortingState == .mostRecentlyRequested
            ),
        ]
    }

    func makeApplySortingAction(
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListRadioOptionsViewModel.Action {
        PaymentRequestsListRadioOptionsViewModel.Action(
            title: L10n.PaymentRequest.List.Chip.Unpaid.RadioOptionsSheet.Action.title,
            style: .largePrimary,
            handler: { [weak delegate] in
                delegate?.applySortingAction()
            }
        )
    }
}
