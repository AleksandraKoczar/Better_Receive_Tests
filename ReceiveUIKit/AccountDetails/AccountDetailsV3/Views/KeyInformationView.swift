import Neptune
import SwiftUI

final class KeyInformationViewModel: ObservableObject {
    let title: String
    let chips: [ChipViewModel]
    let items: [KeyInformationItem]
    let onContainerTap: (KeyInformationType) -> Void
    let trackChipSelected: (KeyInformationType) -> Void

    @Published
    var selectedChip: ChipViewModel
    @Published
    var selectedItem: KeyInformationItem

    init(
        title: String,
        chips: [ChipViewModel],
        items: [KeyInformationItem],
        selectedChip: ChipViewModel,
        selectedItem: KeyInformationItem,
        onContainerTap: @escaping (KeyInformationType) -> Void,
        trackChipSelected: @escaping (KeyInformationType) -> Void
    ) {
        self.title = title
        self.selectedChip = selectedChip
        self.selectedItem = selectedItem
        self.items = items
        self.chips = chips
        self.onContainerTap = onContainerTap
        self.trackChipSelected = trackChipSelected
    }

    func selectChip(_ chip: ChipViewModel) {
        selectedChip = chip
        if let item = items.first(where: { $0.type == chip.type }) {
            selectedItem = item
        }
        trackChipSelected(chip.type)
    }

    struct ChipViewModel: Identifiable, Equatable {
        let id = UUID()
        let type: KeyInformationType
        let title: String

        init(
            title: String,
            type: KeyInformationType
        ) {
            self.title = title
            self.type = type
        }
    }
}

class KeyInformationItem: ObservableObject {
    let type: KeyInformationType
    let subtitle: String
    let isDetailSupported: Bool
    let items: [KeyInformationListItemViewModel]

    init(
        type: KeyInformationType,
        subtitle: String,
        isDetailSupported: Bool,
        items: [KeyInformationListItemViewModel]
    ) {
        self.type = type
        self.subtitle = subtitle
        self.isDetailSupported = isDetailSupported
        self.items = items
    }
}

enum KeyInformationType {
    case fees
    case limits
    case speed
}

struct KeyInformationView: View {
    @Theme
    var theme

    @ObservedObject
    var model: KeyInformationViewModel

    public init(
        model: KeyInformationViewModel
    ) {
        self.model = model
    }

    @ViewBuilder
    var titleLabel: some View {
        PlainText(model.title)
            .textStyle(\.subsectionTitle)
            .expandVertically()
    }

    @ViewBuilder
    var chipsView: some View {
        HStack(spacing: theme.spacing.horizontal.value8) {
            ForEach(model.chips) { chip in
                Chip(
                    title: chip.title,
                    isActive: model.selectedChip == chip,
                    action: {
                        model.selectChip(chip)
                    }
                )
            }
        }
    }

    @ViewBuilder
    var subtitleLabel: some View {
        PlainText(model.selectedItem.subtitle)
            .textStyle(\.defaultBody)
            .expandVertically()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.horizontal.value16) {
            titleLabel
            chipsView
            subtitleLabel
            KeyInformationContainerView(
                model: model.selectedItem
            )
            .contentShape(Rectangle())
            .onTapGesture {
                model.onContainerTap(model.selectedItem.type)
            }
        }
    }
}
