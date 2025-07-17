import Neptune

struct AccountDetailsListItemViewStyle {
    let title: LabelStyle
    let value: LabelStyle
    let buttonStyle: SmallPrimaryButtonAppearance

    init(
        title: LabelStyle = LabelStyle.defaultBody,
        value: LabelStyle = LabelStyle.value,
        buttonStyle: SmallPrimaryButtonAppearance = .smallPrimary
    ) {
        self.title = title
        self.value = value
        self.buttonStyle = buttonStyle
    }
}
