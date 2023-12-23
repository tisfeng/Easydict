//
//  ChangeFontSizeView.swift
//  macdemo
//
//  Created by jk on 2023/11/30.
//

import AppKit
import Foundation
import Hue

@objc public class ChangeFontSizeView: NSView {
    @objc static let changeFontSizeNotificationName = "changeFontSizeNotification"

    let fontSizes: [CGFloat]
    lazy var scaleLines = fontSizes.map { _ in createLine() }

    lazy var selectedScaleLine = createLine()

    @objc var didSelectIndex: ((Int) -> Void)?

    private var horizonLineHeight = 5.0
    private let horizonLineColor = NSColor(hex: "E1E1E1")

    private var scaleLineWidth = 3.0
    private var scaleLineHeight = 11.0
    private let scaleLineColor = NSColor(hex: "CFCFCF")

    private var selectedScaleLineWidth = 8.0
    private var selectedScaleLineHeight = 23.0
    private let selectedScaleLineColor = NSColor(hex: "CCCCCC")

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

        translatesAutoresizingMaskIntoConstraints = false

        let horizonLine = createLine()
        horizonLine.layer?.backgroundColor = horizonLineColor.cgColor
        addSubview(horizonLine)

        NSLayoutConstraint.activate([
            horizonLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizonLine.leftAnchor.constraint(equalTo: leftAnchor),
            horizonLine.rightAnchor.constraint(equalTo: rightAnchor),
            horizonLine.heightAnchor.constraint(equalToConstant: horizonLineHeight),
        ])

        let stackView = NSStackView(views: scaleLines)
        stackView.alignment = .height
        stackView.distribution = .equalSpacing
        stackView.orientation = .horizontal

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: scaleLineHeight),
        ])

        scaleLines.enumerated().forEach { _, view in
            view.layer?.cornerRadius = scaleLineWidth / 2
            view.layer?.backgroundColor = scaleLineColor.cgColor

            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: scaleLineWidth),
            ])
        }

        addSubview(selectedScaleLine)
        selectedScaleLine.layer?.cornerRadius = selectedScaleLineWidth / 2
        selectedScaleLine.layer?.backgroundColor = selectedScaleLineColor.cgColor
        selectedScaleLine.layer?.borderWidth = 0.5
        selectedScaleLine.layer?.borderColor = NSColor(hex: "D7D8D8").cgColor
    }

    override public func layout() {
        super.layout()

        updateSelectedLineFrame()
    }

    private func updateSelectedLineFrame() {
        selectedScaleLine.frame = selectedLineTargetFrame()

//        print("[DEBUG] selectedLine.frame: ", selectedLine.frame)
    }

    private func selectedLineTargetFrame() -> NSRect {
        let y = bounds.height / 2
        let index = max(0, min(selectedIndex, scaleLines.count - 1))
        let x = index == 0 ? 0 : (bounds.width / CGFloat(scaleLines.count - 1)) * CGFloat(index)
        let frame = NSRect(x: round(x) - selectedScaleLineWidth / 2, y: y - selectedScaleLineHeight / 2, width: selectedScaleLineWidth, height: selectedScaleLineHeight)
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

        let index = point.x / (bounds.width / CGFloat(scaleLines.count - 1))

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
                self.selectedScaleLine.animator().frame = self.selectedLineTargetFrame()
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
