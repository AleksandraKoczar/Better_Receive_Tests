import TWFoundation

// sourcery: Buildable
public struct AccountDetailsStatusHeader: Equatable {
    let title: String
    let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
