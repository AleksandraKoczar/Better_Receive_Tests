import UIKit

// sourcery: AutoMockable
protocol SalarySwitchOptionSelectionRouter: AnyObject {
    func displayShareSheet(content: String, sender: UIView)
    func displayOwnershipProofDocument(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate?
    )
}

final class SalarySwitchOptionSelectionRouterImpl: SalarySwitchOptionSelectionRouter {
    private weak var navigationHost: UIViewController?

    init(navigationHost: UIViewController) {
        self.navigationHost = navigationHost
    }

    func displayShareSheet(content: String, sender: UIView) {
        let activityViewController = UIActivityViewController.universalSharingController(
            forItems: [content],
            sourceView: sender
        )

        navigationHost?.present(
            activityViewController,
            animated: UIView.shouldAnimate
        )
    }

    func displayOwnershipProofDocument(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate?
    ) {
        let interactionController = UIDocumentInteractionController(url: url)
        interactionController.name = ""
        interactionController.delegate = delegate
        interactionController.presentPreview(animated: UIView.shouldAnimate)
    }
}
