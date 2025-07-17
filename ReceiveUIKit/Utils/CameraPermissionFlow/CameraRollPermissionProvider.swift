import Photos
import UIKit

enum CameraRollPermissionState {
    case unknown
    case denied
    case granted
}

// sourcery: AutoMockable
protocol CameraRollPermissionProvider {
    func getCameraRollPermissionState() -> CameraRollPermissionState
    func requestAccess(_ completion: @escaping (Bool) -> Void)
    func saveImage(image: UIImage, _ completion: @escaping (Bool) -> Void)
}

final class CameraRollPermissionProviderImpl: CameraRollPermissionProvider {
    func saveImage(image: UIImage, _ completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
            }
        }, completionHandler: { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        })
    }

    func getCameraRollPermissionState() -> CameraRollPermissionState {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return .granted
        case .denied,
             .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        case .limited:
            return .granted
        @unknown default:
            return .denied
        }
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}
