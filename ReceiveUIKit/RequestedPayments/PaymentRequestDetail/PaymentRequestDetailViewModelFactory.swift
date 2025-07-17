import Combine
import Neptune
import ReceiveKit
import TransferResources
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentRequestDetailViewModelDelegate: AnyObject {
    func copyTapped(_ value: String)
    func shareOptionsTapped(viewModel: PaymentRequestDetailShareOptionsViewModel)
    func paymentMethodSummariesTapped(viewModel: PaymentRequestDetailPaymentMethodsViewModel)
    func viewAttachmentFileTapped(_ file: RequestorAttachmentFile)
    func paymentDetailsTapped(action: PaymentRequestDetailsSection.Item.OptionItemAction)
    func cancelPaymentRequestTapped(requestType: PaymentRequestDetails.RequestType)
    func cancelPaymentRequestConfirmed()
    func markAsPaidTapped(requestType: PaymentRequestDetails.RequestType)
    func markAsPaidConfirmed()
    func shareWithQRCodeTapped()
    func shareSheetTapped()
    func fetchAvatarViewModel(
        urlString: String,
        fallbackImage: UIImage,
        badge: UIImage?
    ) -> AnyPublisher<AvatarViewModel, Never>
    func sectionHeaderActionTapped(urnString: String)
}

// sourcery: AutoMockable
protocol PaymentRequestDetailViewModelFactory {
    func make(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> AnyPublisher<PaymentRequestDetailViewModel, Never>

    func makeCancelConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel

    func makeMarkAsPaidConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel
}

struct PaymentRequestDetailViewModelFactoryImpl: PaymentRequestDetailViewModelFactory {
    func make(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> AnyPublisher<PaymentRequestDetailViewModel, Never> {
        makeHeaderViewModel(
            from: paymentRequestDetails,
            delegate: delegate
        ).map { header in
            PaymentRequestDetailViewModel(
                header: header,
                sections: makeSectionViewModels(
                    from: paymentRequestDetails.sections,
                    delegate: delegate
                ),
                footer: makeFooterViewModel(
                    from: paymentRequestDetails,
                    delegate: delegate
                )
            )
        }.eraseToAnyPublisher()
    }

    func makeCancelConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel {
        switch requestType {
        case .invoice:
            InfoSheetViewModel(
                title: L10n.PaymentRequest.Detail.Cancel.Invoice.title,
                message: L10n.PaymentRequest.Detail.Cancel.Invoice.description,
                confirmAction: .init(
                    title: L10n.PaymentRequest.Detail.Cancel.Invoice.cancel,
                    handler: { [weak delegate] in
                        delegate?.cancelPaymentRequestConfirmed()
                    }
                ),
                cancelAction: .init(
                    title: L10n.PaymentRequest.Detail.Cancel.Invoice.back,
                    handler: {}
                )
            )
        case .singleUse,
             .reusable,
             .unknown:
            InfoSheetViewModel(
                title: L10n.PaymentRequest.Detail.Cancel.title,
                message: L10n.PaymentRequest.Detail.Cancel.description,
                confirmAction: .init(
                    title: L10n.PaymentRequest.Detail.Cancel.cancel,
                    handler: { [weak delegate] in
                        delegate?.cancelPaymentRequestConfirmed()
                    }
                ),
                cancelAction: .init(
                    title: L10n.PaymentRequest.Detail.Cancel.back,
                    handler: {}
                )
            )
        }
    }

    func makeMarkAsPaidConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel {
        switch requestType {
        case .invoice:
            InfoSheetViewModel(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.title,
                message: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.description,
                confirmAction: .init(
                    title: L10n.PaymentRequest.Detail.MarkAsPaid.confirm,
                    handler: { [weak delegate] in
                        delegate?.markAsPaidConfirmed()
                    }
                ),
                cancelAction: .init(
                    title: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.back,
                    handler: {}
                ),
                footer: .extended()
            )
        case .singleUse,
             .reusable,
             .unknown:
            InfoSheetViewModel(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.title,
                message: L10n.PaymentRequest.Detail.MarkAsPaid.description,
                confirmAction: .init(
                    title: L10n.PaymentRequest.Detail.MarkAsPaid.confirm,
                    handler: { [weak delegate] in
                        delegate?.markAsPaidConfirmed()
                    }
                ),
                cancelAction: .init(
                    title: L10n.PaymentRequest.Detail.MarkAsPaid.back,
                    handler: {}
                ),
                footer: .extended()
            )
        }
    }
}

// MARK: - Header

private extension PaymentRequestDetailViewModelFactoryImpl {
    func makeIcon(from urnString: String) -> UIImage {
        if let urn = try? URN(urnString) {
            if let image = IconFactory.icon(urn: urn) {
                return image
            } else if IconFactory.isApplePayURN(urn) {
                return WiseAtomsAssets.Assets.applePay.image
            }
        }
        return Icons.fastFlag.image
    }

    func makeBadge(
        from badge: PaymentRequestDetails.Badge?
    ) -> UIImage? {
        badge.map {
            switch $0 {
            case .warning:
                Icons.alert.image
            case .positive:
                Icons.check.image
            }
        }
    }

    func makeIconStyle(
        from badge: PaymentRequestDetails.Badge?
    ) -> AvatarViewStyle {
        guard let badge else {
            return .size56
        }
        return .size56.with {
            switch badge {
            case .warning:
                $0.badge = .warning()
            case .positive:
                $0.badge = .positive()
            }
        }
    }

    func makeAvatarViewModel(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> AnyPublisher<AvatarViewModel, Never> {
        let fallbackImage = makeIcon(from: paymentRequestDetails.icon)
        let badge = makeBadge(from: paymentRequestDetails.badge)
        guard let avatar = paymentRequestDetails.avatar else {
            return .just(
                AvatarViewModel.icon(fallbackImage, badge: badge)
            )
        }
        switch avatar {
        case let .avatar(urlString):
            return delegate.fetchAvatarViewModel(
                urlString: urlString,
                fallbackImage: fallbackImage,
                badge: badge
            )
        case let .initials(value):
            return .just(
                AvatarViewModel.initials(
                    Initials(value: value),
                    badge: badge
                )
            )
        }
    }

    func makeHeaderViewModel(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> AnyPublisher<PaymentRequestDetailViewModel.HeaderViewModel, Never> {
        makeAvatarViewModel(
            from: paymentRequestDetails,
            delegate: delegate
        ).map { avatarViewModel in
            PaymentRequestDetailViewModel.HeaderViewModel(
                icon: avatarViewModel,
                iconStyle: makeIconStyle(from: paymentRequestDetails.badge),
                title: paymentRequestDetails.title,
                subtitle: paymentRequestDetails.subtitle
            )
        }.eraseToAnyPublisher()
    }
}

// MARK: - Sections

private extension PaymentRequestDetailViewModelFactoryImpl {
    private enum ShareOption: CaseIterable {
        case copy
        case qrCode
        case share
    }

    func makeShareOptionsViewModel(
        paymentLink: String,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> PaymentRequestDetailShareOptionsViewModel {
        PaymentRequestDetailShareOptionsViewModel(
            paymentLink: paymentLink,
            options: [
                OptionViewModel(
                    title: L10n.PaymentRequest.Detail.PaymentLink.Options.copy,
                    avatar: .icon(Icons.link.image)
                ),
                OptionViewModel(
                    title: L10n.PaymentRequest.Detail.PaymentLink.Options.qrCode,
                    avatar: .icon(Icons.qrCode.image)
                ),
                OptionViewModel(
                    title: L10n.PaymentRequest.Detail.PaymentLink.Options.share,
                    avatar: .icon(Icons.shareIos.image)
                ),
            ],
            handler: { [weak delegate] index, _ in
                guard let delegate, let option = ShareOption.allCases[safe: index] else {
                    return
                }
                switch option {
                case .copy:
                    delegate.copyTapped(paymentLink)
                case .qrCode:
                    delegate.shareWithQRCodeTapped()
                case .share:
                    delegate.shareSheetTapped()
                }
            }
        )
    }

    func makePaymentLinkAction(
        paymentLink: String,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action {
        Action(
            title: L10n.PaymentRequest.Detail.PaymentLink.Action.share,
            handler: { [weak delegate] in
                delegate.map {
                    let viewModel = makeShareOptionsViewModel(
                        paymentLink: paymentLink,
                        delegate: $0
                    )
                    $0.shareOptionsTapped(viewModel: viewModel)
                }
            }
        )
    }

    func makePaymentMethodsViewModel(
        title: String,
        summaries: [PaymentRequestDetailsSection.Item.ListItemAction.Summary]
    ) -> PaymentRequestDetailPaymentMethodsViewModel {
        let summaries = summaries.map { summary in
            SummaryViewModel(
                title: summary.title,
                description: summary.description,
                icon: makeIcon(from: summary.icon)
            )
        }
        return PaymentRequestDetailPaymentMethodsViewModel(
            title: title,
            summaries: summaries
        )
    }

    func makeSummaryListAction(
        label: String,
        title: String,
        summaries: [PaymentRequestDetailsSection.Item.ListItemAction.Summary],
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action {
        Action(
            title: label,
            handler: { [weak delegate] in
                delegate.map {
                    let viewModel = makePaymentMethodsViewModel(
                        title: title,
                        summaries: summaries
                    )
                    $0.paymentMethodSummariesTapped(viewModel: viewModel)
                }
            }
        )
    }

    func makeDownloadAction(
        label: String,
        fileId: String,
        fileNameWithExtension: String,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action {
        Action(
            title: label,
            handler: { [weak delegate] in
                delegate.map {
                    let file = RequestorAttachmentFileFactory.make(
                        fileId: fileId,
                        fileNameWithExtension: fileNameWithExtension
                    )
                    $0.viewAttachmentFileTapped(file)
                }
            }
        )
    }

    func makeListItemAction(
        from action: PaymentRequestDetailsSection.Item.ListItemAction?,
        value: String,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action? {
        guard let action else {
            return nil
        }
        switch action {
        case let .copy(label):
            return Action(
                title: label,
                handler: { [weak delegate] in
                    delegate?.copyTapped(value)
                }
            )
        case let .download(label, fileId):
            return makeDownloadAction(
                label: label,
                fileId: fileId,
                fileNameWithExtension: value,
                delegate: delegate
            )
        case let .paymentLink(_, paymentLink):
            return makePaymentLinkAction(
                paymentLink: paymentLink,
                delegate: delegate
            )
        case let .summaryList(label, title, summaries):
            return makeSummaryListAction(
                label: label,
                title: title,
                summaries: summaries,
                delegate: delegate
            )
        }
    }

    func makeListItemViewModel(
        title: String,
        subtitle: String,
        action: PaymentRequestDetailsSection.Item.ListItemAction?,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel {
        .listItem(
            LegacyListItemViewModel(
                title: title,
                subtitle: subtitle,
                action: makeListItemAction(
                    from: action,
                    value: subtitle,
                    delegate: delegate
                )
            )
        )
    }

    func makeOptionItemViewModel(
        title: String,
        subtitle: String,
        icon: String,
        action: PaymentRequestDetailsSection.Item.OptionItemAction,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel? {
        let option = OptionViewModel(
            title: title,
            subtitle: subtitle,
            avatar: .icon(makeIcon(from: icon))
        )
        let viewModel = PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel(
            option: option,
            onTap: { [weak delegate] in
                delegate?.paymentDetailsTapped(action: action)
            }
        )
        return .optionItem(viewModel)
    }

    func makeItemsViewModels(
        from items: [PaymentRequestDetailsSection.Item],
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> [PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel] {
        items.compactMap { item in
            switch item {
            case let .listItem(label, value, action):
                makeListItemViewModel(
                    title: label,
                    subtitle: value,
                    action: action,
                    delegate: delegate
                )
            case let .optionItem(label, value, icon, action):
                makeOptionItemViewModel(
                    title: label,
                    subtitle: value,
                    icon: icon,
                    action: action,
                    delegate: delegate
                )
            case .divider:
                // Ignore this case becase there is no divider on payment request details screen.
                // However, the divider could occur in payment details screen.
                nil
            }
        }
    }

    func makeSectionHeaderViewModel(
        from section: PaymentRequestDetailsSection,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> SectionHeaderViewModel {
        guard let action = section.action,
              case let .link(label, urn) = action else {
            return SectionHeaderViewModel(title: section.title)
        }
        return SectionHeaderViewModel(
            title: section.title,
            action: Action(
                title: label,
                handler: { [weak delegate] in
                    delegate?.sectionHeaderActionTapped(urnString: urn)
                }
            )
        )
    }

    func makeSectionViewModels(
        from sections: [PaymentRequestDetailsSection],
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> [PaymentRequestDetailViewModel.SectionViewModel] {
        sections.map { section in
            PaymentRequestDetailViewModel.SectionViewModel(
                header: makeSectionHeaderViewModel(
                    from: section,
                    delegate: delegate
                ),
                items: makeItemsViewModels(
                    from: section.items,
                    delegate: delegate
                )
            )
        }
    }
}

// MARK: - Footer

private extension PaymentRequestDetailViewModelFactoryImpl {
    func makeFooterViewModel(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> PaymentRequestDetailViewModel.FooterViewModel? {
        let sortedActions = paymentRequestDetails.actions.sorted(by: <)
        let actions: [Action] = sortedActions.compactMap {
            switch $0 {
            case .markAsPaid:
                makeMarkAsPaidAction(from: paymentRequestDetails, delegate: delegate)
            case .cancel:
                makeCancelAction(from: paymentRequestDetails, delegate: delegate)
            case .requestAgain:
                // Clients don't show 'Request Again' even if API returns it
                nil
            }
        }

        guard actions.isNonEmpty else {
            return nil
        }

        return .init(
            primaryAction: actions[0],
            secondaryAction: actions[safe: 1],
            configuration: makeFooterConfiguration(from: sortedActions)
        )
    }

    func makeCancelAction(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action {
        let title =
            switch paymentRequestDetails.type {
            case .invoice:
                L10n.PaymentRequest.Detail.Footer.Invoice.cancel
            case .singleUse,
                 .reusable,
                 .unknown:
                L10n.PaymentRequest.Detail.Footer.cancel
            }

        return Action(
            title: title,
            handler: { [weak delegate] in
                delegate?.cancelPaymentRequestTapped(
                    requestType: paymentRequestDetails.type
                )
            }
        )
    }

    func makeMarkAsPaidAction(
        from paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> Action {
        Action(
            title: L10n.PaymentRequest.Detail.Footer.markAsPaid,
            handler: { [weak delegate] in
                delegate?.markAsPaidTapped(
                    requestType: paymentRequestDetails.type
                )
            }
        )
    }

    func makeFooterConfiguration(from actions: [PaymentRequestDetails.Action]) -> PaymentRequestDetailViewModel.FooterViewModel.Configuration {
        // Clients don't show 'Request Again' even if API returns it
        let actions = actions.filter { $0 != .requestAgain }
        let firstAction = actions.first
        let secondAction = actions[safe: 1]

        switch (firstAction, secondAction) {
        case (.markAsPaid, nil):
            return .positiveOnly
        case (.cancel, nil):
            return .negativeOnly
        case (.markAsPaid, .cancel):
            return .positiveAndNegative
        default:
            return .positiveOnly
        }
    }
}
