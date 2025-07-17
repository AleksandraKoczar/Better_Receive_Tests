import Neptune

extension InlineAlertViewModel.Message {
    var text: String {
        switch self {
        case let .plain(content),
             let .markdown(content):
            content
        }
    }
}
