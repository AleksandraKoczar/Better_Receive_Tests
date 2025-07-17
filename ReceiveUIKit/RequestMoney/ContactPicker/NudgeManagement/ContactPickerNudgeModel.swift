import Neptune

// sourcery: Buildable
struct ContactPickerNudgeModel: Hashable {
    let type: ContactPickerNudgeType
    let title: String
    let icon: NudgeViewModel.Asset
    let ctaTitle: String
}
