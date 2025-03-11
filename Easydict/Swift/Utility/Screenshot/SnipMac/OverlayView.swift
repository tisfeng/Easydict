import SwiftUI

struct ScreenshotOverlayView: View {
    // MARK: Lifecycle

    init(captureType: CaptureType = .screenshot) {
        self.captureType = captureType
        // 在初始化时获取屏幕截图作为背景
        _backgroundImage = State(initialValue: ScreenCaptureManager.takeScreenshot(of: nil))
    }

    // MARK: Internal

    var captureType: CaptureType = .screenshot
    let overlayWindowManager = OverlayWindowManager.shared

    var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let adjustedStartLocation = CGPoint(
                    x: value.startLocation.x,
                    y: value.startLocation.y
                )
                let adjustedLocation = CGPoint(
                    x: value.location.x,
                    y: value.location.y
                )

                let origin = CGPoint(
                    x: min(adjustedStartLocation.x, adjustedLocation.x),
                    y: min(adjustedStartLocation.y, adjustedLocation.y)
                )
                let size = CGSize(
                    width: abs(adjustedLocation.x - adjustedStartLocation.x),
                    height: abs(adjustedLocation.y - adjustedStartLocation.y)
                )

                selectedRect = CGRect(origin: origin, size: size)
                isSelecting = true
            }
            .onEnded { _ in
                if captureType == .screenshot {
                    isSelecting = false
                    overlayWindowManager.hideOverlayWindow()

                    // 从背景图片中裁剪选定区域
                    if selectedRect.width > 10, selectedRect.height > 10 {
                        // 直接使用 ScreenCaptureManager 获取选定区域的截图，而不是裁剪背景图
                        if let croppedImage = ScreenCaptureManager.takeScreenshot(of: selectedRect) {
                            OverlayWindowManager.shared.finishCapture(with: croppedImage)
                        }
                    }
                } else {
                    isSelecting = false
                    overlayWindowManager.hideOverlayWindow()
                }
            }
    }

    var body: some View {
        ZStack {
            // 显示背景截图
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
//                    .opacity(0.7) // 稍微降低不透明度以便用户知道这是截图模式
            }

            GeometryReader { geometry in
                ZStack {
                    // 半透明遮罩层
//                    Rectangle()
//                        .fill(Color.black.opacity(0.2))
//                        .edgesIgnoringSafeArea(.all)

                    if isSelecting {
                        // 选择区域
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .background(Color.clear)
                            .frame(width: selectedRect.width, height: selectedRect.height)
                            .position(
                                x: selectedRect.midX,
                                y: selectedRect.midY
                            )

                        // 清除选择区域的遮罩
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: selectedRect.width, height: selectedRect.height)
                            .position(
                                x: selectedRect.midX,
                                y: selectedRect.midY
                            )
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()

                // 手势识别层
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(drag)
            }
        }
    }

    // MARK: Private

    @State private var selectedRect = CGRect.zero
    @State private var isSelecting = false
    @State private var backgroundImage: NSImage?

    // 裁剪图片的辅助方法
    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage {
        let croppedImage = NSImage(size: rect.size)
        croppedImage.lockFocus()

        // 调整坐标系（SwiftUI 和 Core Graphics 坐标系不同）
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        // 从原图中裁剪
        image.draw(
            in: NSRect(origin: .zero, size: rect.size),
            from: flippedRect,
            operation: .copy,
            fraction: 1.0
        )

        croppedImage.unlockFocus()
        return croppedImage
    }
}
