//
//  ChangeFontSizeView.swift
//  macdemo
//
//  Created by jk on 2023/11/30.
//

import AppKit
import Foundation

@objc public class ChangeFontSizeView: NSView {
    @objc static let changeFontSizeNotificationName = "changeFontSizeNotification"

    let fontSizes: [CGFloat]
    lazy var verticalLines = fontSizes.map { _ in createLine() }

    lazy var selectedLine = createLine()

    @objc var didSelectIndex: ((Int) -> Void)?

    private var selectedIndex = 1

    @objc public init(fontSizes: [CGFloat], initialIndex: Int) {
        self.fontSizes = fontSizes
        selectedIndex = initialIndex
        super.init(frame: .zero)

        setupUI()

        NotificationCenter.default.addObserver(forName: .init(Self.changeFontSizeNotificationName), object: nil, queue: .main) { [weak self] noti in
            guard let self, let index = noti.object as? Int, index != self.selectedIndex else { return }
            self.selectedIndex = index
            self.updateSelectedLineFrame()
        }
    }

    private func setupUI() {
        clipsToBounds = false
        wantsLayer = true
        needsLayout = true

//        layer?.backgroundColor = NSColor.purple.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        let horizonLine = createLine()
        horizonLine.layer?.backgroundColor = NSColor(red: 65 / 255, green: 65 / 255, blue: 65 / 255, alpha: 1).cgColor
        addSubview(horizonLine)

        NSLayoutConstraint.activate([
            horizonLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizonLine.leftAnchor.constraint(equalTo: leftAnchor),
            horizonLine.rightAnchor.constraint(equalTo: rightAnchor),
            horizonLine.heightAnchor.constraint(equalToConstant: 5),
        ])

        let stackView = NSStackView(views: verticalLines)
        stackView.alignment = .height
        stackView.distribution = .equalSpacing
        stackView.orientation = .horizontal

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 10),
        ])

        verticalLines.enumerated().forEach { _, view in
            view.layer?.backgroundColor = NSColor(red: 90 / 255, green: 90 / 255, blue: 90 / 255, alpha: 1).cgColor
            view.layer?.cornerRadius = 1
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 3),
            ])
        }

        addSubview(selectedLine)
        selectedLine.layer?.cornerRadius = 3
        selectedLine.layer?.backgroundColor = NSColor(red: 130 / 255, green: 130 / 255, blue: 130 / 255, alpha: 1).cgColor
    }

    override public func layout() {
        super.layout()

        updateSelectedLineFrame()
    }

    private func updateSelectedLineFrame() {
        selectedLine.frame = selectedLineTargetFrame()

//        print("[DEBUG] selectedLine.frame: ", selectedLine.frame)
    }

    private func selectedLineTargetFrame() -> NSRect {
        let y = bounds.height / 2
        let width: CGFloat = 7
        let height: CGFloat = 20

        let index = max(0, min(selectedIndex, verticalLines.count - 1))

        let x = index == 0 ? 0 : (bounds.width / CGFloat(verticalLines.count - 1)) * CGFloat(index)

        let frame = NSRect(x: round(x) - width / 2, y: y - height / 2, width: width, height: height)
        return frame
    }

    override public func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        handleEvent(event: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        handleEvent(event: event, animated: false)
    }

    private func handleEvent(event: NSEvent, animated: Bool = true) {
        let location = event.locationInWindow
        let point = convert(location, from: nil)

        let index = point.x / (bounds.width / CGFloat(verticalLines.count - 1))

        var targetIndex = Int(round(index))
        targetIndex = max(0, targetIndex)
        targetIndex = min(targetIndex, fontSizes.count - 1)

        if targetIndex != selectedIndex {
            updateIndex(targetIndex, animated: animated)
        }
    }

    private func updateIndex(_ index: Int, animated: Bool) {
        var targetIndex = index
        targetIndex = max(0, targetIndex)
        targetIndex = min(targetIndex, fontSizes.count - 1)

        guard selectedIndex != targetIndex else { return }

        selectedIndex = targetIndex

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.selectedLine.animator().frame = self.selectedLineTargetFrame()
            } completionHandler: {
                self.updateSelectedLineFrame()
            }

        } else {
            updateSelectedLineFrame()
        }

        didSelectIndex?(selectedIndex)
    }

    private func createLine() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.cgColor

        return view
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
