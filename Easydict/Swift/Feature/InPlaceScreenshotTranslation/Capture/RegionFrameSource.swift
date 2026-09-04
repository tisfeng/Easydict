//
//  RegionFrameSource.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - CapturedRegionFrame

/// One complete, in-memory ScreenCaptureKit frame and its non-sensitive metadata.
struct CapturedRegionFrame: @unchecked Sendable {
    let image: CGImage
    let capturedAt: TimeInterval
    let dirtyRects: [CGRect]?
}

// MARK: - RegionFrameSourceError

/// Sanitized capture failures that drive recoverable session state.
enum RegionFrameSourceError: Error, Equatable, Sendable {
    case permissionDenied
    case displayUnavailable
    case currentApplicationUnavailable
    case invalidSelection
    case streamStopped
    case frameConversionFailed
}

// MARK: - RegionFrameSource

/// Production boundary for a single live fixed-region frame stream.
protocol RegionFrameSource: AnyObject, Sendable {
    func start(
        onFrame: @escaping @Sendable (CapturedRegionFrame) -> (),
        onFailure: @escaping @Sendable (RegionFrameSourceError) -> ()
    ) async throws

    func stop() async
}
