import Neptune
@testable import ReceiveUIKit

final class AccountDetailsMultipleSelectionViewMock: AccountDetailsMultipleSelectionView {
    var lastHeaderViewModel: LargeTitleViewModel?
    var lastViewModel: AccountDetailsMultipleSelectionViewModel?
    var buttonStateEnabled = false
    var showHudCalled = false
    var hideHudCalled = false
    var snackBarPresentedMessage: String?

    func configureHeader(viewModel: LargeTitleViewModel) {
        lastHeaderViewModel = viewModel
    }

    func updateList(viewModel: AccountDetailsMultipleSelectionViewModel) {
        lastViewModel = viewModel
    }

    func updateButtonState(enabled: Bool) {
        buttonStateEnabled = enabled
    }

    func presentSnackBar(message: String) {
        snackBarPresentedMessage = message
    }

    func showHud() {
        showHudCalled = true
    }

    func hideHud() {
        hideHudCalled = true
    }
}
