import ApiKit
import Neptune
import TWFoundation

extension ReceiveMethodsDFFlow {
    struct SuccessResult: Decodable {
        let title: String
        let body: String
        let buttons: [Button]
        let type: ResultType
        let visual: Visual

        struct Button: Decodable {
            let title: String
        }

        enum ResultType: String, Decodable, DefaultDecodable {
            case successScreen = "SUCCESS_SCREEN"
            case other

            static var defaultValue: SuccessResult.ResultType = .other
        }

        enum Visual: String, DefaultDecodable {
            case success = "SUCCESS"
            case pending = "PENDING"
            case other

            static var defaultValue: SuccessResult.Visual = .other

            var illustration: IllustrationView.Asset {
                switch self {
                case .success:
                    .scene3D(.checkMark)
                case .pending:
                    .image(Illustrations.sandTimer.image)
                case .other:
                    .scene3D(.globe)
                }
            }
        }
    }
}
