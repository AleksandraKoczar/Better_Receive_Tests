import Combine
import CombineSchedulers
import ContactsKit
import Foundation
import Neptune

// sourcery: AutoMockable
protocol CancellableAvatarFetcher {
    func fetch(
        publisher: AvatarPublisher,
        completion: @escaping ((ContactsKit.AvatarModel) -> Void)
    )
    func cancel()
}

final class CancellableAvatarFetcherImpl {
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var avatarFetchingCancellable: AnyCancellable?

    init(scheduler: AnySchedulerOf<DispatchQueue>) {
        self.scheduler = scheduler
    }
}

// MARK: - ContactAvatarFetcher

extension CancellableAvatarFetcherImpl: CancellableAvatarFetcher {
    func fetch(
        publisher: AvatarPublisher,
        completion: @escaping ((AvatarModel) -> Void)
    ) {
        avatarFetchingCancellable = publisher
            .avatarPublisher
            .receive(on: scheduler)
            .sink(receiveValue: { avatarModel in
                completion(avatarModel)
            })
    }

    func cancel() {
        avatarFetchingCancellable = nil
    }
}
