import SwiftUI
import UIKit
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers

struct CameraCapture: UIViewControllerRepresentable {
    let completion: (URL?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera; picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeHigh; picker.videoMaximumDuration = 30
        picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (URL?) -> Void
        init(completion: @escaping (URL?) -> Void) { self.completion = completion }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.mediaURL] as? URL)
        }
    }
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let completion: (Result<URL, Error>?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(); config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos]); config.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator; return controller
    }
    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (Result<URL, Error>?) -> Void
        init(completion: @escaping (Result<URL, Error>?) -> Void) { self.completion = completion }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else { completion(nil); return }
            let type = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ? UTType.movie : UTType.image
            provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                let result: Result<URL, Error>
                do {
                    guard let url else { throw error ?? NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "The photo library could not provide this file."]) }
                    let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                    try FileManager.default.copyItem(at: url, to: copy); result = .success(copy)
                } catch { result = .failure(error) }
                DispatchQueue.main.async { self.completion(result) }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
