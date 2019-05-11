import UIKit
import PlaygroundSupport

// NSLayoutManager EXTENSION
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
    private var originalText: String!
    private var originalAttributedText: NSAttributedString!
    private var maximumNumberOfLinesAllowed: Int = 3

    private var shouldTrim: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    // OVERRIDE INTERNAL PROPERTIES
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
    
    // OVERRIDE INTERNAL METHODS
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

        if pointInTrimTextRange(point: point){
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
        // Read more text
        let moreTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font!,
            .foregroundColor: UIColor.lightGray
        ]
        let moreText = NSAttributedString(string: "more", attributes: moreTextAttributes)
        let readMoreText = NSMutableAttributedString(string: "... ")
        readMoreText.append(moreText)
        
        textContainer.maximumNumberOfLines = maximumNumberOfLinesAllowed
        // below method takes glyphs into account?
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.characterRangeThatFits(textContainer: textContainer), actualCharacterRange: nil)
        
        textContainer.size = CGSize(width: bounds.size.width, height: .greatestFiniteMagnitude)
        var rangeToReplace = layoutManager.characterRangeThatFits(textContainer: textContainer)
        rangeToReplace.location = NSMaxRange(rangeToReplace) - readMoreText.length
        rangeToReplace.length = textStorage.length - rangeToReplace.location
        textStorage.replaceCharacters(in: rangeToReplace, with: readMoreText)
        
        invalidateIntrinsicContentSize()
    }
    
    private func resetText() {
        print("Reset text view")
        maximumNumberOfLinesAllowed = 0
        textContainer.maximumNumberOfLines = maximumNumberOfLinesAllowed
        shouldTrim = false
        if originalAttributedText != nil {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: attributedText!.length), with: originalAttributedText)
        } else if originalText != nil {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: text!.count), with: originalText)
        }
        invalidateIntrinsicContentSize()
    }
    
    private func pointInTrimTextRange(point: CGPoint) -> Bool {
        let boundingRect = layoutManager.boundingRectForCharacterRange(range: NSRange(location: 131, length: 5), container: textContainer)
        return boundingRect.contains(point)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MY VIEW
let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
view.backgroundColor = UIColor.yellow

// TEST TEXT
let testText = "A wealthy American business magnate, playboy, and ingenious scientist, Anthony Edward Tony Stark. He suffers a severe 😎 chest inj🇮🇳ury during ♥️ a kidnapping."
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

// TEXT VIEW AUTO-LAYOUT CONSTRAINTS
view.addSubview(myTextView)
myTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
myTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
myTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true

// PLAYGROUND VARS
PlaygroundPage.current.liveView = view
PlaygroundPage.current.needsIndefiniteExecution = true


