import Combine
import ContactsKit
import Neptune

// sourcery: AutoMockable
protocol AvatarLoadableNavigationOptionTableViewCellPresenter: AnyObject {
    func start(
        title: String,
        subtitle: String,
        avatarPublisher: AvatarPublisher,
        cell: AvatarLoadableNavigationOptionTableViewCell
    )
    func prepareForReuse()
}

final class AvatarLoadableNavigationOptionTableViewCellPresenterImpl {
    private var avatarFetcher: CancellableAvatarFetcher

    init(avatarFetcher: CancellableAvatarFetcher) {
        self.avatarFetcher = avatarFetcher
    }
}

extension AvatarLoadableNavigationOptionTableViewCellPresenterImpl: AvatarLoadableNavigationOptionTableViewCellPresenter {
    func start(
        title: String,
        subtitle: String,
        avatarPublisher: AvatarPublisher,
        cell: AvatarLoadableNavigationOptionTableViewCell
    ) {
        avatarFetcher.fetch(
            publisher: avatarPublisher,
            completion: { [weak cell] avatarModel in
                cell?.configure(
                    with: OptionViewModel(
                        title: title,
                        subtitle: subtitle,
                        avatar: avatarModel.asAvatarViewModel()
                    )
                )
            }
        )
    }

    func prepareForReuse() {
        avatarFetcher.cancel()
    }
}
