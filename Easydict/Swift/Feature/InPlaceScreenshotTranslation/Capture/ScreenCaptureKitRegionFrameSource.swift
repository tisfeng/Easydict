//
//  ScreenCaptureKitRegionFrameSource.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreImage
import CoreMedia
import CoreVideo
import Foundation
@preconcurrency import ScreenCaptureKit

// MARK: - ScreenCaptureKitRegionFrameSource

/// Captures a fixed display-relative rectangle at 2 fps while excluding every
/// Easydict window. Frames remain in memory and are delivered from a serial queue.
final class ScreenCaptureKitRegionFrameSource: NSObject, RegionFrameSource, @unchecked Sendable {
    // MARK: Lifecycle

    init(selection: ScreenshotSelection) {
        self.selection = selection
        super.init()
    }

    // MARK: Internal

    func start(
        onFrame: @escaping @Sendable (CapturedRegionFrame) -> (),
        onFailure: @escaping @Sendable (RegionFrameSourceError) -> ()
    ) async throws {
        let operation = try beginStartOperation()
        guard CGPreflightScreenCaptureAccess() else {
            throw RegionFrameSourceError.permissionDenied
        }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: false
        )
        try ensureCurrent(operation)
        guard let display = content.displays.first(where: { $0.displayID == selection.displayID })
        else {
            throw RegionFrameSourceError.displayUnavailable
        }
        guard let currentApplication = content.applications.first(where: {
            $0.processID == ProcessInfo.processInfo.processIdentifier
        }) else {
            throw RegionFrameSourceError.currentApplicationUnavailable
        }

        let displayBounds = CGRect(origin: .zero, size: display.frame.size)
        let sourceRect = selection.sourceRectInDisplayPoints.intersection(displayBounds)
        guard sourceRect.width > 1, sourceRect.height > 1 else {
            throw RegionFrameSourceError.invalidSelection
        }

        let filter = SCContentFilter(
            display: display,
            excludingApplications: [currentApplication],
            exceptingWindows: []
        )
        let configuration = makeConfiguration(sourceRect: sourceRect)
        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)

        guard install(
            stream: stream,
            operation: operation,
            onFrame: onFrame,
            onFailure: onFailure
        ) else {
            try? stream.removeStreamOutput(self, type: .screen)
            throw CancellationError()
        }

        do {
            try await stream.startCapture()
            try ensureCurrent(operation, stream: stream)
        } catch {
            let ownedOperation = detach(stream: stream, operation: operation)
            try? await stream.stopCapture()
            try? stream.removeStreamOutput(self, type: .screen)
            guard ownedOperation,
                  !Task.isCancelled,
                  !(error is CancellationError)
            else {
                throw CancellationError()
            }
            if !CGPreflightScreenCaptureAccess() {
                throw RegionFrameSourceError.permissionDenied
            }
            throw error
        }
    }

    func stop() async {
        let stream: SCStream? = lock.withLock {
            operationGeneration &+= 1
            let currentStream = self.stream
            self.stream = nil
            onFrame = nil
            onFailure = nil
            return currentStream
        }
        if let stream {
            try? await stream.stopCapture()
            try? stream.removeStreamOutput(self, type: .screen)
        }
    }

    // MARK: Private

    private let selection: ScreenshotSelection
    private let sampleQueue = DispatchQueue(
        label: "com.izual.easydict.in-place-translation.capture",
        qos: .userInitiated
    )
    private let imageContext = CIContext(options: [.cacheIntermediates: false])
    private let lock = NSLock()

    private var stream: SCStream?
    private var onFrame: (@Sendable (CapturedRegionFrame) -> ())?
    private var onFailure: (@Sendable (RegionFrameSourceError) -> ())?
    private var operationGeneration: UInt64 = 0

    private static func evenDimension(_ value: CGFloat) -> Int {
        let rounded = max(2, Int(value.rounded()))
        return rounded.isMultiple(of: 2) ? rounded : rounded + 1
    }

    private func makeConfiguration(sourceRect: CGRect) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = sourceRect
        let requestedWidth = sourceRect.width * selection.backingScaleFactor
        let requestedHeight = sourceRect.height * selection.backingScaleFactor
        let longEdge = max(requestedWidth, requestedHeight)
        let scale = min(1, CGFloat(InPlaceTranslationConstants.maximumCaptureLongEdge) / longEdge)
        configuration.width = Self.evenDimension(requestedWidth * scale)
        configuration.height = Self.evenDimension(requestedHeight * scale)
        configuration.minimumFrameInterval = CMTime(
            seconds: InPlaceTranslationConstants.samplingInterval,
            preferredTimescale: 600
        )
        configuration.queueDepth = 2
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = false
        configuration.capturesAudio = false
        return configuration
    }

    /// Reserves a start generation without disturbing an already-running stream.
    /// A second pending start supersedes the first before either installs state.
    private func beginStartOperation() throws -> UInt64 {
        try lock.withLock {
            guard stream == nil else {
                throw RegionFrameSourceError.streamStopped
            }
            operationGeneration &+= 1
            return operationGeneration
        }
    }

    private func ensureCurrent(_ operation: UInt64, stream expectedStream: SCStream? = nil) throws {
        guard !Task.isCancelled,
              lock.withLock({
                  guard operationGeneration == operation else { return false }
                  if let expectedStream {
                      return stream === expectedStream
                  }
                  return stream == nil
              })
        else {
            throw CancellationError()
        }
    }

    private func install(
        stream: SCStream,
        operation: UInt64,
        onFrame: @escaping @Sendable (CapturedRegionFrame) -> (),
        onFailure: @escaping @Sendable (RegionFrameSourceError) -> ()
    )
        -> Bool {
        lock.withLock {
            guard operationGeneration == operation, self.stream == nil else { return false }
            self.stream = stream
            self.onFrame = onFrame
            self.onFailure = onFailure
            return true
        }
    }

    /// Detaches state only when both the stream identity and operation token
    /// still belong to this start. An old failure can never clear a newer stream.
    private func detach(stream: SCStream, operation: UInt64) -> Bool {
        lock.withLock {
            guard operationGeneration == operation, self.stream === stream else { return false }
            operationGeneration &+= 1
            self.stream = nil
            onFrame = nil
            onFailure = nil
            return true
        }
    }

    private func frameHandler(for callbackStream: SCStream)
        -> (@Sendable (CapturedRegionFrame) -> ())? {
        lock.withLock {
            guard stream === callbackStream else { return nil }
            return onFrame
        }
    }

    /// Unexpected termination atomically consumes the handler for that exact
    /// stream. Delegate callbacks from detached streams are ignored.
    private func failureHandlerForStoppedStream(_ callbackStream: SCStream)
        -> (@Sendable (RegionFrameSourceError) -> ())? {
        lock.withLock {
            guard stream === callbackStream else { return nil }
            operationGeneration &+= 1
            stream = nil
            onFrame = nil
            defer { onFailure = nil }
            return onFailure
        }
    }

    private func failureHandler(for callbackStream: SCStream)
        -> (@Sendable (RegionFrameSourceError) -> ())? {
        lock.withLock {
            guard stream === callbackStream else { return nil }
            return onFailure
        }
    }
}

// MARK: SCStreamOutput

extension ScreenCaptureKitRegionFrameSource: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard frameHandler(for: stream) != nil,
              outputType == .screen,
              sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(
                  sampleBuffer,
                  createIfNecessary: false
              ) as? [[SCStreamFrameInfo: Any]],
              let frameInfo = attachments.first,
              let statusRawValue = frameInfo[.status] as? Int,
              SCFrameStatus(rawValue: statusRawValue) == .complete,
              let pixelBuffer = sampleBuffer.imageBuffer
        else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let image = imageContext.createCGImage(ciImage, from: ciImage.extent) else {
            failureHandler(for: stream)?(.frameConversionFailed)
            return
        }
        let dirtyRects = frameInfo[.dirtyRects] as? [CGRect]
        frameHandler(for: stream)?(
            CapturedRegionFrame(
                image: image,
                capturedAt: ProcessInfo.processInfo.systemUptime,
                dirtyRects: dirtyRects
            )
        )
    }
}

// MARK: SCStreamDelegate

extension ScreenCaptureKitRegionFrameSource: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        guard let handler = failureHandlerForStoppedStream(stream) else { return }
        let category: RegionFrameSourceError = CGPreflightScreenCaptureAccess()
            ? .streamStopped
            : .permissionDenied
        handler(category)
    }
}

// MARK: - NSLock

extension NSLock {
    /// Executes a short state mutation while guaranteeing unlock on every path.
    fileprivate func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
