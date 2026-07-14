import SwiftUI
import AVFoundation
import UIKit

/// A SwiftUI view that wraps AVCaptureVideoPreviewLayer and manages orientation natively
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    class Coordinator: NSObject {
        var rotationObservation: NSKeyValueObservation?
        var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
        
        func setupRotationCoordinator(for previewLayer: AVCaptureVideoPreviewLayer) {
            guard let session = previewLayer.session,
                  let input = session.inputs.first(where: { $0 is AVCaptureDeviceInput }) as? AVCaptureDeviceInput else {
                return
            }
            
            let device = input.device
            
            // Create RotationCoordinator linked to this device and preview layer
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
            self.rotationCoordinator = coordinator
            
            // KVO observe the preview rotation angle which automatically handles long/short edge camera offsets on all iPads
            rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak previewLayer] coord, change in
                guard let previewLayer = previewLayer, let connection = previewLayer.connection else { return }
                if let angle = change.newValue {
                    if connection.isVideoRotationAngleSupported(angle) {
                        connection.videoRotationAngle = angle
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .clear
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        
        // Wait for connection to be active before binding coordinator
        DispatchQueue.main.async {
            context.coordinator.setupRotationCoordinator(for: view.previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Automatically handled by the KVO RotationCoordinator
    }
}
