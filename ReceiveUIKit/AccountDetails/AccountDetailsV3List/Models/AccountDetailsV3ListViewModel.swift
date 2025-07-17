import Foundation
import Neptune

final class AccountDetailsV3ListViewModel: ObservableObject {
    let title: String
    let subtitle: String
    private let originalSections: [Section]
    let onSearchTapped: () -> Void

    @Published
    var searchText = "" {
        didSet {
            filterCurrencies()
        }
    }

    @Published
    private(set) var sections = [Section]()

    init(
        title: String,
        subtitle: String,
        originalSections: [Section],
        onSearchTapped: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.originalSections = originalSections
        self.onSearchTapped = onSearchTapped
        sections = originalSections
    }

    private func filterCurrencies() {
        guard searchText.isNonEmpty else {
            sections = originalSections
            return
        }

        let filteredSections = originalSections.compactMap { section -> Section? in
            let filteredItems = section.items.filter { item in
                let words = item.title.lowercased().split(separator: " ")
                let matchingWords = words.contains { $0.hasPrefix(searchText.lowercased()) }
                let matchingKeywords = item.keywords.contains { $0.lowercased() == searchText.lowercased() }
                return matchingKeywords || matchingWords
            }
            return filteredItems.isEmpty ? nil : Section(title: section.title, items: filteredItems)
        }
        sections = filteredSections
    }
}

extension AccountDetailsV3ListViewModel {
    // sourcery: AutoEquatableForTest
    struct Section: Identifiable {
        let id = UUID()
        let title: String?
        let items: [Item]

        // sourcery: AutoEquatableForTest
        struct Item: Identifiable {
            let id = UUID()
            let avatar: AvatarViewModel
            let title: String
            let subtitle: String?
            let keywords: [String]
            // sourcery:skipEquality
            let onTapAction: (() -> Void)?
        }
    }
}
