//
//  SelectableText.swift
//  ActionForAnimals
//

import SwiftUI
import UIKit

struct SelectableText: UIViewRepresentable {
    let attributedString: AttributedString
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let nsAttr = NSMutableAttributedString(attributedString)
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let fullRange = NSRange(location: 0, length: nsAttr.length)

        // Apply base font size while preserving bold/italic traits from markdown
        nsAttr.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            if let existingFont = value as? UIFont {
                let traits = existingFont.fontDescriptor.symbolicTraits
                if let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) {
                    nsAttr.addAttribute(.font, value: UIFont(descriptor: descriptor, size: baseFont.pointSize), range: range)
                } else {
                    nsAttr.addAttribute(.font, value: baseFont, range: range)
                }
            } else {
                nsAttr.addAttribute(.font, value: baseFont, range: range)
            }
        }

        nsAttr.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        textView.attributedText = nsAttr

        DispatchQueue.main.async {
            height = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity)).height
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false
        }
    }
}

struct SelectableTextView: View {
    let attributedString: AttributedString
    @State private var height: CGFloat = 100

    var body: some View {
        SelectableText(attributedString: attributedString, height: $height)
            .frame(height: height)
    }
}
