//
//  Utils.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/11/23.
//

import AppKit
import Foundation

func withMenubarClosed(_ action: @escaping () -> ()) {
    NotificationCenter.default.post(name: .closePopover, object: nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        action()
    }
}

func calculateCropRect(from selectedRect: CGRect) -> CGRect {
    guard let screen = NSScreen.main else { return CGRect.zero }
    let scaleFactor = screen.backingScaleFactor

    let flippedRect = CGRect(
        x: selectedRect.origin.x,
        y: screen.frame.height - selectedRect.origin.y - selectedRect.height,
        width: selectedRect.width,
        height: selectedRect.height
    )

    let scaledRect = CGRect(
        x: flippedRect.origin.x * scaleFactor,
        y: flippedRect.origin.y * scaleFactor,
        width: flippedRect.width * scaleFactor,
        height: flippedRect.height * scaleFactor
    )

    return scaledRect
}

// MARK: - CaptureType

enum CaptureType {
    case screenshot
    case screenRecord
}

extension Notification.Name {
    static let closePopover = Notification.Name("ClosePopoverNotification")
}
