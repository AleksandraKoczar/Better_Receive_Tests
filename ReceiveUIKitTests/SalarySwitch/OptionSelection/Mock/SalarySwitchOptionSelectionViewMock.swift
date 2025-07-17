@testable import ReceiveUIKit
import UIKit

final class SalarySwitchOptionSelectionViewMock: UIView, SalarySwitchOptionSelectionView {
    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        get { underlyingDocumentInteractionControllerDelegate }
        set(value) { underlyingDocumentInteractionControllerDelegate = value }
    }

    private var underlyingDocumentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate!

    // MARK: - configure

    private(set) var configureReceivedViewModel: SalarySwitchOptionSelectionViewModel?
    private(set) var configureReceivedInvocations: [SalarySwitchOptionSelectionViewModel] = []
    private(set) var configureCallsCount = 0
    var configureClosure: ((SalarySwitchOptionSelectionViewModel) -> Void)?
    var configureCalled: Bool {
        configureCallsCount > 0
    }

    func configure(viewModel: SalarySwitchOptionSelectionViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showErrorAlert

    private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    private(set) var showErrorAlertCallsCount = 0
    var showErrorAlertClosure: ((String, String) -> Void)?
    var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }

    // MARK: - showHud

    private(set) var showHudCallsCount = 0
    var showHudClosure: (() -> Void)?
    var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    private(set) var hideHudCallsCount = 0
    var hideHudClosure: (() -> Void)?
    var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}
