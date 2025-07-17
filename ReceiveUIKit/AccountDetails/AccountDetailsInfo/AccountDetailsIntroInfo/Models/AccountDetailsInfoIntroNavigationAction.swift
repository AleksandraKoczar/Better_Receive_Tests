import Neptune

struct AccountDetailsInfoIntroNavigationAction {
    let viewModel: OptionViewModel
    let action: @MainActor () -> Void
}
