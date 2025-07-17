import UIKit

struct QuickPayCarouselViewModel {
    let cards: [QuickpayCardViewModel]
    let onTap: (_ card: QuickpayCardViewModel) -> Void
}

// sourcery: AutoEquatableForTest
struct QuickpayCardViewModel: Identifiable {
    let id: Int
    // sourcery: skipEquality
    let image: UIImage
    let title: String
    let subtitle: String
    let articleId: String
}
