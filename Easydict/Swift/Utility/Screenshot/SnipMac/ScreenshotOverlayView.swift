import AppKit
import SwiftUI

// MARK: - ScreenshotOverlayView

struct ScreenshotOverlayView2: View {
    // MARK: Internal

    var captureType: CaptureType

    var body: some View {
        ZStack {
            // 显示全屏截图作为背景
            if let image = capturedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            // 选择区域的矩形
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    startPoint = value.startLocation
                                    isDragging = true
                                }

                                let width = value.location.x - startPoint.x
                                let height = value.location.y - startPoint.y

                                selectionRect = CGRect(
                                    x: width > 0 ? startPoint.x : value.location.x,
                                    y: height > 0 ? startPoint.y : value.location.y,
                                    width: abs(width),
                                    height: abs(height)
                                )
                            }
                            .onEnded { value in
                                isDragging = false
                                if selectionRect.width > 10, selectionRect.height > 10 {
                                    captureSelectedArea()
                                }
                            }
                    )

                // 绘制选择框
                if isDragging {
                    Path { path in
                        path.addRect(selectionRect)
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
            }
        }
    }

    // MARK: Private

    @State private var selectionRect: CGRect = .zero
    @State private var isDragging = false
    @State private var startPoint: CGPoint = .zero

    // 获取 OverlayWindowManager 中的截图
    private var capturedImage: NSImage? {
        OverlayWindowManager.shared.capturedImage
    }

    private func captureSelectedArea() {
        guard let fullImage = capturedImage else { return }

        // 从全屏截图中裁剪选择区域
        let croppedImage = cropImage(fullImage, to: selectionRect)

        // 回调到 OverlayWindowManager
        OverlayWindowManager.shared.finishCapture(with: croppedImage)
    }

    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!

        // 调整坐标系（SwiftUI 和 Core Graphics 坐标系不同）
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: image.size.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        let croppedCGImage = cgImage.cropping(to: flippedRect)!
        let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)

        return croppedImage
    }
}
