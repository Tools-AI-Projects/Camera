//
//  CaptureProbes.swift of MijickCamera
//
//  Debug-only helpers to verify AVCaptureSession lifecycle.
//

#if DEBUG
import Foundation
import AVFoundation

public func installCaptureProbes() {
    let nc = NotificationCenter.default
    nc.addObserver(forName: .AVCaptureSessionDidStartRunning, object: nil, queue: .main) { notification in
        print("🔵 AVCaptureSessionDidStartRunning:", notification.object ?? "nil")
    }
    nc.addObserver(forName: .AVCaptureSessionDidStopRunning, object: nil, queue: .main) { notification in
        print("🟢 AVCaptureSessionDidStopRunning:", notification.object ?? "nil")
    }
}
#endif


