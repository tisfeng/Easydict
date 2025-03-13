//
//  ScreenCaptureHelper.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/12.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import ScreenCaptureKit

// MARK: - ScreenCaptureHelper

class ScreenCaptureHelper: NSObject {
    // MARK: Internal

    static let shared = ScreenCaptureHelper()

    func takeScreenshot(of rect: CGRect, completion: @escaping (NSImage?) -> ()) {
        NSLog("Taking screenshot of rect: \(rect)")

        captureHandler = completion
        captureRect = rect

        Task {
            do {
                let content = try await SCShareableContent.current

                var bestDisplay: SCDisplay?
                var maxOverlapArea: CGFloat = 0

                for display in content.displays {
                    let intersection = display.frame.intersection(rect)
                    if !intersection.isNull {
                        let overlapArea = intersection.width * intersection.height
                        if overlapArea > maxOverlapArea {
                            maxOverlapArea = overlapArea
                            bestDisplay = display
                        }
                    }
                }

                guard let display = bestDisplay else {
                    NSLog("No display found containing rect: \(rect)")
                    completion(nil)
                    return
                }

                NSLog("Selected display: \(display.frame) for rect: \(rect)")

                // 计算相对于显示器的偏移量
                let displayBounds = display.frame
                let relativeRect = CGRect(
                    x: rect.origin.x - displayBounds.origin.x,
                    y: rect.origin.y - displayBounds.origin.y,
                    width: rect.width,
                    height: rect.height
                )

                NSLog("Relative rect: \(relativeRect)")

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()

                // 获取屏幕缩放因子
                guard let screen = NSScreen.screens.first(where: {
                    NSRectToCGRect($0.frame).contains(rect)
                })
                else {
                    completion(nil)
                    return
                }

                NSLog("Screen frame: \(screen.frame)")

                let scale = screen.backingScaleFactor

                NSLog("Display scale factor: \(scale)")

                // 使用显示器的完整分辨率
                config.width = Int(displayBounds.width * scale)
                config.height = Int(displayBounds.height * scale)
                config.pixelFormat = kCVPixelFormatType_32BGRA

                // 保存显示器信息用于后续处理
                captureDisplayInfo = (displayBounds: displayBounds, scale: scale)

                stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                try await stream?.startCapture()
            } catch {
                print("Screenshot error: \(error)")
                completion(nil)
            }
        }
    }

    // MARK: Private

    private var stream: SCStream?
    private var captureHandler: ((NSImage?) -> ())?
    private var captureRect: CGRect? // 保存原始截图区域
    private var captureDisplayInfo: (displayBounds: CGRect, scale: CGFloat)? // 保存显示器信息
}

// MARK: SCStreamOutput

extension ScreenCaptureHelper: SCStreamOutput {
    func stream(
        _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen,
              let handler = captureHandler,
              let captureRect = captureRect,
              let displayInfo = captureDisplayInfo
        else { return }

        if let cgImage = imageFromSampleBuffer(sampleBuffer) {
            // 计算高分辨率下的裁剪区域
            let scale = displayInfo.scale
            let relativeRect = CGRect(
                x: (captureRect.origin.x - displayInfo.displayBounds.origin.x) * scale,
                y: (captureRect.origin.y - displayInfo.displayBounds.origin.y) * scale,
                width: captureRect.width * scale,
                height: captureRect.height * scale
            )

            NSLog("Cropping image at: \(relativeRect)")

            // 裁剪图像
            if let croppedImage = cgImage.cropping(to: relativeRect) {
                let image = NSImage(
                    cgImage: croppedImage,
                    size: NSSize(width: captureRect.width, height: captureRect.height)
                )
                NSLog("Captured image: \(image)")

                // 调用回调
                handler(image)
            } else {
                NSLog("Failed to crop image")
                handler(nil)
            }

            // 清理资源
            captureHandler = nil
            self.captureRect = nil
            captureDisplayInfo = nil

            // 停止捕获
            Task {
                try? await stream.stopCapture()
                self.stream = nil
            }
        }
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
