import SwiftUI
import AVFoundation
import UIKit

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

        override func layoutSubviews() {
            super.layoutSubviews()
            CameraPreviewView.configureVideoConnection(previewLayer.connection)
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .clear
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            CameraPreviewView.configureVideoConnection(view.previewLayer.connection)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        Self.configureVideoConnection(uiView.previewLayer.connection)
    }

    private static func configureVideoConnection(_ connection: AVCaptureConnection?) {
        guard let connection else { return }

        let angle = videoRotationAngleForCurrentInterface()
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    private static func videoRotationAngleForCurrentInterface() -> CGFloat {
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation

        switch orientation {
        case .portrait: return 0
        case .portraitUpsideDown: return 180
        case .landscapeLeft: return 270
        case .landscapeRight: return 90
        default: return 0
        }
    }
}
