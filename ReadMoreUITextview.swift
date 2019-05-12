import UIKit
import PlaygroundSupport

// NSLayoutManager Extension
extension NSLayoutManager {
    
    //  Returns character range that completely fits into the container
    public func characterRangeThatFits(textContainer: NSTextContainer) -> NSRange {
        var rangeThatFits = self.glyphRange(for: textContainer)
        rangeThatFits = self.characterRange(forGlyphRange: rangeThatFits, actualGlyphRange: nil)
        return rangeThatFits
    }
    
    // Return boudning rect in provided container for characters in given range
    public func boundingRectForCharacterRange(range: NSRange, container: NSTextContainer) -> CGRect {
        let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: container)
        return boundingRect
    }
}

// CUSTOM TEXT VIEW CLASS
class CustomTextView: UITextView {
    
    // Private properties
    private var originalText: String!
    private var originalAttributedText: NSAttributedString!
    private let maximumNumberOfLinesAllowed: Int = 3
    private var shouldTrim: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    private let moreText = NSMutableAttributedString(string: "more")

    // Override internal properties
    override var text: String! {
        didSet {
            originalText = text
            originalAttributedText = nil
        }
    }
    
    override var attributedText: NSAttributedString! {
        didSet {
            originalAttributedText = attributedText
            originalText = nil
        }
    }
    
    // Override internal methods
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupDefaults()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if originalNumberOfLines() > 0 {
            if originalNumberOfLines() > maximumNumberOfLinesAllowed && shouldTrim {
                updateText()
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var originalIntrinsicContentSize = super.intrinsicContentSize
        originalIntrinsicContentSize.width = UIView.noIntrinsicMetric
        return originalIntrinsicContentSize
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if pointInTrimTextRange(point: point) && shouldTrim {
            resetText()
        }
    }
    
    // Private Methods
    private func setupDefaults() {
        
        isScrollEnabled = false
        isEditable = false
        isSelectable = false
        isUserInteractionEnabled = true
        
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0.0
        
    }
    
    private func originalNumberOfLines() -> Int {
        guard let font = font else { return 0 }
        let originalNumberOfLines = Int((bounds.size.height - textContainerInset.top - textContainerInset.bottom) / font.lineHeight)
        return originalNumberOfLines
    }
    
    private func updateText() {
        // Trim text (more) attributes
        let moreTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font!,
            .foregroundColor: UIColor.lightGray
        ]
        moreText.addAttributes(moreTextAttributes, range: NSRange(location: 0, length: moreText.length))
        let trimText = NSMutableAttributedString(string: "... ")
        trimText.append(moreText)
        
        textContainer.maximumNumberOfLines = maximumNumberOfLinesAllowed
        // below method takes glyphs into account?
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.characterRangeThatFits(textContainer: textContainer), actualCharacterRange: nil)
        textContainer.size = CGSize(width: bounds.size.width, height: .greatestFiniteMagnitude)
        
        let rangeToReplace = rangeToReplaceWithTrimText()
        textStorage.replaceCharacters(in: rangeToReplace, with: trimText)
        
        invalidateIntrinsicContentSize()
    }
    
    private func resetText() {
        textContainer.maximumNumberOfLines = 0
        shouldTrim = false
        if originalAttributedText != nil {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: attributedText!.length), with: originalAttributedText)
        } else if originalText != nil {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: text!.count), with: originalText)
        }
        invalidateIntrinsicContentSize()
    }
    
    private func rangeToReplaceWithTrimText() -> NSRange {
        var rangeToReplace = layoutManager.characterRangeThatFits(textContainer: textContainer)
        rangeToReplace.location = NSMaxRange(rangeToReplace) - moreText.length - 4
        rangeToReplace.length = textStorage.length - rangeToReplace.location
        return rangeToReplace
    }
    
    private func trimTextRange() -> NSRange {
        var trimTextRange = rangeToReplaceWithTrimText()
        trimTextRange.location = trimTextRange.location + moreText.length
        trimTextRange.length = moreText.length + 1
        return trimTextRange
    }
    
    // Hit-Test
    private func pointInTrimTextRange(point: CGPoint) -> Bool {
        let boundingRect = layoutManager.boundingRectForCharacterRange(range: trimTextRange(), container: textContainer)
        return boundingRect.contains(point)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// View
let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
view.backgroundColor = UIColor.yellow

// Test text
let testText = "A wealthy American business magnate, playboy, and ingenious scientist, Anthony Edward Tony Stark. 🇮🇳 He suffers a severe 😎 chest injury during ♥️ a kidnapping."
let attributes: [NSAttributedString.Key: Any] = [
    .font: UIFont.preferredFont(forTextStyle: .caption1)
]
let attrText = NSMutableAttributedString(string: testText, attributes: attributes)

let myTextView: CustomTextView = {
    let tv = CustomTextView()
    
    tv.attributedText = attrText
    
    tv.layer.borderWidth = 1
    tv.layer.borderColor = UIColor.black.cgColor
    tv.backgroundColor = .white
    tv.translatesAutoresizingMaskIntoConstraints = false
    return tv
}()

// Text view auto-layout constraints
view.addSubview(myTextView)
myTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
myTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
myTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true

// Playground vars
PlaygroundPage.current.liveView = view
PlaygroundPage.current.needsIndefiniteExecution = true
