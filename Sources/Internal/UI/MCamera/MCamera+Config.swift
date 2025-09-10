//
//  MCamera+Config.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI
import UIKit
import AVFoundation

extension MCamera { @MainActor class Config {
    // MARK: Screens
    var cameraScreen: CameraScreenBuilder = DefaultCameraScreen.init
    var capturedMediaScreen: CapturedMediaScreenBuilder? = nil
    var errorScreen: ErrorScreenBuilder = DefaultCameraErrorScreen.init

    // MARK: Actions
    var imageCapturedAction: (UIImage, MCamera.Controller) -> () = { _,_ in }
    var videoCapturedAction: (URL, MCamera.Controller) -> () = { _,_ in }
    var closeMCameraAction: () -> () = {}

    // MARK: Others
    var appDelegate: MApplicationDelegate.Type? = nil
    var isCameraConfigured: Bool = false
    var shouldLockOrientationInPortrait: Bool = false

    // MARK: Initial Settings (applied on first camera appear)
    var initialOutputType: CameraOutputType?
    var initialCameraPosition: CameraPosition?
    var initialIsAudioAvailable: Bool?
    var initialZoomFactor: CGFloat?
    var initialFlashMode: CameraFlashMode?
    var initialLightMode: CameraLightMode?
    var initialResolution: AVCaptureSession.Preset?
    var initialFrameRate: Int32?
    var initialExposureDuration: CMTime?
    var initialTargetBias: Float?
    var initialISO: Float?
    var initialExposureMode: AVCaptureDevice.ExposureMode?
    var initialHDRMode: CameraHDRMode?
    var initialFilters: [CIFilter]?
    var initialMirrorOutput: Bool?
    var initialGridVisibility: Bool?

    // MARK: Focus indicator customization
    var focusImage: UIImage?
    var focusImageColor: UIColor?
    var focusImageSize: CGFloat?
}}
