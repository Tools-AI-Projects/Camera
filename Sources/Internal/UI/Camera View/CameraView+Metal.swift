//
//  CameraView+Metal.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI
import MetalKit
import AVKit
import UIKit

@MainActor class CameraMetalView: MTKView {
    private(set) weak var parent: CameraManager?
    private(set) var ciContext: CIContext!
    private(set) var commandQueue: MTLCommandQueue!
    private(set) var currentFrame: CIImage?
    private(set) var focusIndicator: CameraFocusIndicatorView = .init()
    private(set) var isAnimating: Bool = false
}

// MARK: Setup
extension CameraMetalView {
    func setup(parent: CameraManager) throws(MCameraError) {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { throw .cannotSetupMetalDevice }

        self.assignInitialValues(parent: parent, metalDevice: metalDevice)
        self.configureMetalView(metalDevice: metalDevice)
        if let containerView = parent.cameraView { self.addToParent(containerView) }
    }
}
private extension CameraMetalView {
    func assignInitialValues(parent: CameraManager, metalDevice: MTLDevice) {
        self.parent = parent
        self.ciContext = CIContext(mtlDevice: metalDevice)
        self.commandQueue = metalDevice.makeCommandQueue()
    }
    func configureMetalView(metalDevice: MTLDevice) {
        self.alpha = 0

        self.delegate = self
        self.device = metalDevice
        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.autoResizeDrawable = false
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}


// MARK: - ANIMATIONS



// MARK: Camera Entrance
extension CameraMetalView {
    func performCameraEntranceAnimation() {
        UIView.animate(withDuration: 0.33) { self.alpha = 1 }
    }
}

// MARK: Image Capture
extension CameraMetalView {
    func performImageCaptureAnimation() {
        let blackMatte = createBlackMatte()
        guard let cameraView = parent?.cameraView else { return }
        cameraView.addSubview(blackMatte)
        animateBlackMatte(blackMatte)
    }
}
private extension CameraMetalView {
    func createBlackMatte() -> UIView {
        let view = UIView()
        if let container = parent?.cameraView {
            view.frame = container.bounds
        } else {
            view.frame = .zero
        }
        if let color = UIColor(named: "mijick-background-primary", in: .module, compatibleWith: nil) {
            view.backgroundColor = color
        } else {
            view.backgroundColor = .black
        }
        view.alpha = 0
        return view
    }
    func animateBlackMatte(_ view: UIView) {
        UIView.animate(withDuration: 0.16, animations: { view.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.16, animations: { view.alpha = 0 }) { _ in
                view.removeFromSuperview()
            }
        }
    }
}

// MARK: Camera Flip
extension CameraMetalView {
    func beginCameraFlipAnimation() async {
        let snapshot = createSnapshot()
        isAnimating = true
        insertBlurView(snapshot)
        animateBlurFlip()

        await Task.sleep(seconds: 0.01)
    }
    func finishCameraFlipAnimation() async {
        guard let cameraView = parent?.cameraView else { return }

        await Task.sleep(seconds: 0.44)
        // Re-fetch the blur view after delay to avoid stale references if hierarchy changed
        guard let blurView = cameraView.viewWithTag(.blurViewTag) else { isAnimating = false; return }
        UIView.animate(withDuration: 0.3, animations: { [weak blurView] in
            blurView?.alpha = 0
        }) { [weak self, weak blurView] _ in
            // Ensure the view is still attached before removing
            if let view = blurView, view.superview != nil {
                view.removeFromSuperview()
            }
            self?.isAnimating = false
        }
    }
}
private extension CameraMetalView {
    func createSnapshot() -> UIImage? {
        guard let currentFrame else { return nil }

        let image = UIImage(ciImage: currentFrame)
        return image
    }
    func insertBlurView(_ snapshot: UIImage?) {
        guard let cameraView = parent?.cameraView else { return }
        let blurView = UIImageView(frame: cameraView.frame)
        blurView.image = snapshot
        blurView.contentMode = .scaleAspectFill
        blurView.clipsToBounds = true
        blurView.tag = .blurViewTag
        blurView.applyBlurEffect(style: .regular)
        cameraView.addSubview(blurView)
    }
    func animateBlurFlip() {
        if let cameraView = parent?.cameraView {
            UIView.transition(with: cameraView, duration: 0.44, options: cameraFlipAnimationTransition) {}
        }
    }
}
private extension CameraMetalView {
    var cameraFlipAnimationTransition: UIView.AnimationOptions { parent?.attributes.cameraPosition == .back ? .transitionFlipFromLeft : .transitionFlipFromRight }
}

// MARK: Camera Focus
extension CameraMetalView {
    func performCameraFocusAnimation(touchPoint: CGPoint) {
        removeExistingFocusIndicatorAnimations()

        let focusIndicator = focusIndicator.create(at: touchPoint)
        guard let cameraView = parent?.cameraView else { return }
        cameraView.addSubview(focusIndicator)
        animateFocusIndicator(focusIndicator)
    }
}
private extension CameraMetalView {
    func removeExistingFocusIndicatorAnimations() { if let cameraView = parent?.cameraView, let view = cameraView.viewWithTag(.focusIndicatorTag) {
        view.removeFromSuperview()
    }}
    func animateFocusIndicator(_ focusIndicator: UIImageView) {
        UIView.animate(withDuration: 0.44, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, animations: { [weak focusIndicator] in
            focusIndicator?.transform = .init(scaleX: 1, y: 1)
        }) { _ in
            UIView.animate(withDuration: 0.44, delay: 1.44, animations: { [weak focusIndicator] in
                focusIndicator?.alpha = 0.2
            }) { _ in
                UIView.animate(withDuration: 0.44, delay: 1.44, animations: { [weak focusIndicator] in
                    focusIndicator?.alpha = 0
                }) { _ in
                    focusIndicator.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: Camera Orientation
extension CameraMetalView {
    func beginCameraOrientationAnimation(if shouldAnimate: Bool) async { if shouldAnimate {
        if let cameraView = parent?.cameraView { cameraView.alpha = 0 }
        await Task.sleep(seconds: 0.1)
    }}
    func finishCameraOrientationAnimation(if shouldAnimate: Bool) { if shouldAnimate {
        guard let cameraView = parent?.cameraView else { return }
        UIView.animate(withDuration: 0.2, delay: 0.1) { cameraView.alpha = 1 }
    }}
}


// MARK: - CAPTURING FRAMES



// MARK: Capture
extension CameraMetalView: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let currentFrame = captureCurrentFrame(cvImageBuffer)
        let currentFrameWithFiltersApplied = applyingFiltersToCurrentFrame(currentFrame)
        redrawCameraView(currentFrameWithFiltersApplied)

        // Safety: ensure the preview becomes visible on first frame (first launch)
        if self.alpha == 0 {
            DispatchQueue.main.async { [weak self] in self?.performCameraEntranceAnimation() }
        }
    }
}
private extension CameraMetalView {
    func captureCurrentFrame(_ cvImageBuffer: CVImageBuffer) -> CIImage {
        let currentFrame = CIImage(cvImageBuffer: cvImageBuffer)
        return currentFrame.oriented(parent?.attributes.frameOrientation ?? .right)
    }
    func applyingFiltersToCurrentFrame(_ currentFrame: CIImage) -> CIImage {
        currentFrame.applyingFilters(parent?.attributes.cameraFilters ?? [])
    }
    func redrawCameraView(_ frame: CIImage) {
        currentFrame = frame
        draw()
    }
}

// MARK: Draw
extension CameraMetalView: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let ciImage = currentFrame,
              let currentDrawable = view.currentDrawable
        else { return }

        changeDrawableSize(view, ciImage)
        renderView(view, currentDrawable, commandBuffer, ciImage)
        commitBuffer(currentDrawable, commandBuffer)
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
private extension CameraMetalView {
    func changeDrawableSize(_ view: MTKView, _ ciImage: CIImage) {
        view.drawableSize = ciImage.extent.size
    }
    func renderView(_ view: MTKView, _ currentDrawable: any CAMetalDrawable, _ commandBuffer: any MTLCommandBuffer, _ ciImage: CIImage) { ciContext.render(
        ciImage,
        to: currentDrawable.texture,
        commandBuffer: commandBuffer,
        bounds: .init(origin: .zero, size: view.drawableSize),
        colorSpace: CGColorSpaceCreateDeviceRGB()
    )}
    func commitBuffer(_ currentDrawable: any CAMetalDrawable, _ commandBuffer: any MTLCommandBuffer) {
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
