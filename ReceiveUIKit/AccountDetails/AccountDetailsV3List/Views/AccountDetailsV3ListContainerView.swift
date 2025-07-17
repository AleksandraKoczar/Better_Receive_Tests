import Neptune
import SwiftUI
import TransferResources

struct AccountDetailsV3ListContainerView: View {
    @Theme
    private var theme

    @ObservedObject
    var model: AccountDetailsV3ListViewModel

    @Environment(\.preferredMaxLayoutWidth)
    private var preferredMaxLayoutWidth

    public var body: some View {
        VStack(spacing: theme.spacing.vertical.betweenSections) {
            headerView()
            searchInput()
            if model.sections.isNonEmpty {
                ForEach(model.sections) { section in
                    VStack {
                        sectionTitle(title: section.title)
                        sectionList(section: section)
                    }
                }
            } else {
                emptyView()
            }
        }
    }

    func emptyView() -> some View {
        TemplateLayout(emptyViewModel: .init(
            illustrationConfiguration: .init(asset: .image(Illustrations.magnifyingGlass.image)),
            title: L10n.AccountDetailsV3.List.NoResults.title,
            message: .text(L10n.AccountDetailsV3.List.NoResults.subtitle)
        ))
    }

    func searchInput() -> some View {
        SearchInput(
            text: $model.searchText,
            label: nil,
            placeholder: ""
        )
        .sentiment(.none)
        .preferredPadding()
        .enabled(true)
        .onTap {
            model.onSearchTapped()
        }
    }

    func headerView() -> some View {
        VStack(spacing: theme.spacing.vertical.value4) {
            PlainText(model.title)
                .textStyle(\.screenTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.horizontal.componentDefault)
            PlainText(model.subtitle)
                .textStyle(\.largeBody)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.horizontal.componentDefault)
        }
        .padding(.top, theme.spacing.vertical.value24)
    }

    func sectionTitle(title: String?) -> some View {
        Group {
            if let title {
                PlainText(title)
                    .textStyle(\.bodyTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, theme.spacing.horizontal.componentDefault)
            }
        }
    }

    public func option(item: AccountDetailsV3ListViewModel.Section.Item) -> some View {
        let style = AvatarViewStyle.size48.with {
            $0.badge = .iconStyle(
                tintColor: \.base.dark,
                secondaryTintColor: \.sentiment.warning.primary
            )
        }
        let option = Option(
            title: item.title,
            subtitle: item.subtitle,
            leadingView: .avatar(item.avatar),
            avatarStyle: style,
            accessibilityLabel: nil
        )
        return HStack(spacing: .zero) {
            option
            Chevron()
                .spacing(leading: \.componentDefault)
                .interactiveStyle()
        }
        .preferredMaxLayoutWidth(
            preferredMaxLayoutWidth,
            trailingPadding: theme.size(SemanticSize.icon.size16).width + theme.spacing.horizontal.componentDefault
        )
        .padding(.horizontal, theme.spacing.horizontal.componentDefault)
    }

    func sectionList(section: AccountDetailsV3ListViewModel.Section) -> some View {
        ForEach(section.items, id: \.id) { item in
            option(item: item)
                .onTap {
                    item.onTapAction?()
                }
        }
    }
}
