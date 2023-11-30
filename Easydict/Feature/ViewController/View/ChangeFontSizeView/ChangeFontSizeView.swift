//
//  ChangeFontSizeView.swift
//  macdemo
//
//  Created by jk on 2023/11/30.
//

import Foundation
import AppKit

@objc public class ChangeFontSizeView: NSView {
    
    @objc static let changeFontSizeNotificationName = "changeFontSizeNotification"
    
    let fontSizes: [CGFloat]
    lazy var verticalLines = fontSizes.map { _ in createLine() }
    
    lazy var selectedLine = createLine()
    
    @objc var didSelectFontSizeRatio: ((CGFloat)->Void)?
    
    var selectedIndex = 1 {
        didSet {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.selectedLine.animator().frame = self.selectedLineTargetFrame()
            } completionHandler: {
                self.updateSelectedLineFrame()
            }
            
            let ratio = fontSizes[selectedIndex]
            didSelectFontSizeRatio?(ratio)
            
            NotificationCenter.default.post(.init(name: .init(Self.changeFontSizeNotificationName), object: ratio))
        }
    }
    
    @objc public init(fontSizes: [CGFloat], initialIndex: Int) {
        self.fontSizes = fontSizes
        self.selectedIndex = initialIndex
        super.init(frame: .zero)
        
        setupUI()
    }
    
    private func setupUI() {
        
        clipsToBounds = false
        wantsLayer = true
        needsLayout = true
        
//        layer?.backgroundColor = NSColor.purple.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        
        let horizonLine = createLine()
        horizonLine.layer?.backgroundColor = NSColor(red: 65/255, green: 65/255, blue: 65/255, alpha: 1).cgColor
        addSubview(horizonLine)
        
        NSLayoutConstraint.activate([
            horizonLine.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            horizonLine.leftAnchor.constraint(equalTo: self.leftAnchor),
            horizonLine.rightAnchor.constraint(equalTo: self.rightAnchor),
            horizonLine.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        let stackView = NSStackView(views: verticalLines)
        stackView.alignment = .height
        stackView.distribution = .equalSpacing
        stackView.orientation = .horizontal
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 10),
        ])
        
        verticalLines.enumerated().forEach { _, view in
            view.layer?.backgroundColor = NSColor(red: 90/255, green: 90/255, blue: 90/255, alpha: 1).cgColor
            view.layer?.cornerRadius = 1
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 2),
            ])
        }
        
        addSubview(selectedLine)
        selectedLine.layer?.cornerRadius = 3
        selectedLine.layer?.backgroundColor = NSColor(red: 130/255, green: 130/255, blue: 130/255, alpha: 1).cgColor
        
    }
    
    public override func layout() {
        super.layout()
        
        updateSelectedLineFrame()
    }
    
    private func updateSelectedLineFrame() {
        
        selectedLine.frame = selectedLineTargetFrame()
    }
    
    private func selectedLineTargetFrame() -> NSRect {
        let y = bounds.height/2
        let width: CGFloat = 6
        let height: CGFloat = 16
        let x = (bounds.width/CGFloat(verticalLines.count-1)) * CGFloat(selectedIndex)
        
        let frame = NSRect(x: round(x) - width/2, y: y - height/2, width: width, height: height)
        return frame
    }
    
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let location = event.locationInWindow
        let point = convert(location, from: nil)
        
        let index = point.x / (bounds.width/CGFloat(verticalLines.count-1))
        
        selectedIndex = Int(round(index))
    }
    
    private func createLine() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.cgColor
        
        return view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
