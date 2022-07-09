//
//  GHFoldLabel.swift
//
//  Created by gh on 2022/7/1.
//

import Foundation
import UIKit

public enum GHFoldLabelActionType {
    ///收起
    case fold
    /// 展开
    case spread
}

private typealias ElementTuple = (range: NSRange, element: GHFoldLabelActionType)

@IBDesignable open class  GHFoldLabel: UILabel {
        
    open var actionHandler: ((GHFoldLabelActionType) -> ())?
    
    open func handleActionTap(_ handler: @escaping (GHFoldLabelActionType) -> ()) {
        actionHandler = handler
    }
     
    ///当前状态
    var activedType: GHFoldLabelActionType = .spread
    ///折叠时的行数
    @IBInspectable public var minimumLine: Int = 0 {
        didSet {
            self.numberOfLines = 0
            updateTextStorage()
        }
    }

    private var old_attributedText: NSAttributedString?
    override open var attributedText: NSAttributedString? {
        didSet {
            if old_attributedText == nil {
                old_attributedText = attributedText
            }
            updateTextStorage()
        }
    }

    open override var numberOfLines: Int {
        didSet { textContainer.maximumNumberOfLines = numberOfLines }
    }
    
    open override var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setupLabel()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        updateTextStorage()
    }
    
    open override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateTextStorage()
    }
    
    open override var intrinsicContentSize: CGSize {
        guard let text = text, !text.isEmpty else {
            return .zero
        }

        textContainer.size = CGSize(width: self.preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    fileprivate func onTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved, .regionEntered, .regionMoved:
            if let element = element(at: location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    selectedElement = element
                }
                avoidSuperCall = true
            } else {
                selectedElement = nil
            }
        case .ended, .regionExited:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            didTapActionText(selectedElement.element)
            
            let when = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .cancelled:
            selectedElement = nil
        case .stationary:
            break
        @unknown default:
            break
        }
        
        return avoidSuperCall
    }

    // MARK: - private properties
    fileprivate var _customizing: Bool = true
    fileprivate var selectedElement: ElementTuple?
    fileprivate var activedTuple: ElementTuple?
    fileprivate var heightCorrection: CGFloat = 0
    fileprivate lazy var textStorage = NSTextStorage()
    fileprivate lazy var layoutManager = NSLayoutManager()
    fileprivate lazy var textContainer = NSTextContainer()
    
    // MARK: - helper functions
    
    fileprivate func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        isUserInteractionEnabled = true
    }
    
    fileprivate func truncatedText(attributedString: NSAttributedString) -> NSMutableAttributedString {
        guard minimumLine > 0 else {
            return NSMutableAttributedString(attributedString: attributedString)
        }
        //拿到每行数据
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
        let path = CGMutablePath()
        let rect = CGRect(x: 0, y: 0, width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        path.addRect(rect, transform: .identity)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(CFIndex(0), CFIndex(0)), path, nil)
        guard let lines = CTFrameGetLines(frame) as? [CTLine] else {
            return NSMutableAttributedString(attributedString: attributedString)
        }
        var showText = attributedString.string
        var lineArray = [String]()
        for line in lines {
            let lineRef = line
            let lineRange: CFRange? = CTLineGetStringRange(lineRef)
            let range = NSRange(location: lineRange?.location ?? 0, length: lineRange?.length ?? 0)
            let lineString = NSString(string: showText).substring(with: range)
            lineArray.append(lineString)
        }
        //不足最小行数时直接返回，不处理
        guard lineArray.count > minimumLine else {
            return NSMutableAttributedString(attributedString: attributedString)
        }
        let arribute = attributedString.attributes(at: 0, effectiveRange: nil)
        if activedType == .spread {
            showText = lineArray.prefix(minimumLine-1).joined(separator: "")
            let lineText = lineArray[minimumLine-1]
            showText += String(lineText.prefix(max(lineText.count - 5, 0))) + "...展开"
            let newAttStr = NSMutableAttributedString(string: showText, attributes: arribute)
            let range = NSRange(location: showText.count-2, length: 2)
            newAttStr.addAttributes([NSAttributedString.Key.foregroundColor:UIColor.red], range: range)
            activedTuple = (range,.spread)
            return newAttStr
        }else{
            showText.append("收起")
            let newAttStr = NSMutableAttributedString(string: showText, attributes: arribute)
            let range = NSRange(location: showText.count-2, length: 2)
            newAttStr.addAttributes([NSAttributedString.Key.foregroundColor:UIColor.red], range: range)
            activedTuple = (range,.fold)
            return newAttStr
        }
    }
    
    
    fileprivate func updateTextStorage() {
        if _customizing { return }
        guard let attributedText = old_attributedText, attributedText.length > 0 else {
            clearActiveElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
                
        clearActiveElements()
        let mutAttrString = truncatedText(attributedString: attributedText)
        
        textStorage.setAttributedString(mutAttrString)
        _customizing = true
        text = mutAttrString.string
        _customizing = false
        setNeedsDisplay()
    }
    
    fileprivate func clearActiveElements() {
        selectedElement = nil
    }
    
    fileprivate func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
       
    fileprivate func element(at location: CGPoint) -> ElementTuple? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
       if let element = activedTuple {
           if index >= element.range.location && index <= element.range.location + element.range.length {
               return element
            }
        }
        
        return nil
    }
    
    fileprivate func didTapActionText(_ type: GHFoldLabelActionType) {
//        if hashtag {
//            activedType = .fold
//        }else{
//            activedType = .spread
//        }
//        updateTextStorage()
        actionHandler?(type)
    }
    
    //MARK: - Handle UI Responder touches
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesMoved(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = onTouch(touch)
        super.touchesCancelled(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, with: event)
    }
    

}

extension  GHFoldLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
