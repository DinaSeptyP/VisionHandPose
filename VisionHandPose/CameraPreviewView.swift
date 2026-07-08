import SwiftUI
import AVFoundation

/// A SwiftUI view that wraps AVCaptureVideoPreviewLayer to show the live camera feed
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
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .clear
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        
        // Ensure the preview layer fills the view and updates correctly on layout changes
        DispatchQueue.main.async {
            if let connection = view.previewLayer.connection {
                if connection.isVideoRotationAngleSupported(0.0) {
                    connection.videoRotationAngle = 0.0
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Handle orientation or configuration changes if necessary
    }
}
