//
//  CompletionCheckmarkOverlay.swift
//  ActionForAnimals
//
//  Created by Amit Dhuleshia on 9/6/25.
//  Copyright © 2025 Action For Animals. All rights reserved.
//

import SwiftUI

enum CompletionCheckmarkMode { case overlay, replace }

struct CompletionCheckmarkOverlay: ViewModifier {
    let show: Bool
    let containerSize: CGFloat
    let mode: CompletionCheckmarkMode

    // tweak as you like
    private var overlayScale: CGFloat { 0.44 }   // % of container for corner badge
    private var replaceScale: CGFloat { 1.0 }   // % of container when replacing

    func body(content: Content) -> some View {
        let checkSize = containerSize * (mode == .overlay ? overlayScale : replaceScale)
        ZStack(alignment: mode == .overlay ? .bottomTrailing : .center) {
            // Hide base image if we're in replace mode and showing the check
            content.opacity(mode == .replace && show ? 0 : 1)

            if show {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: checkSize, height: checkSize)
                    .foregroundColor(.afaGreen)
                    .background { Circle().foregroundColor(.white) }
                    .shadow(radius: mode == .overlay ? 1 : 0)
                    .padding(mode == .overlay ? containerSize * 0.06 : 0) // keep corner badge inside bounds
                    .accessibilityHidden(true)
            }
        }
    }
}

extension View {
    func completionCheckmarkOverlay(
        show: Bool,
        containerSize: CGFloat,
        mode: CompletionCheckmarkMode = .overlay
    ) -> some View {
        modifier(CompletionCheckmarkOverlay(show: show, containerSize: containerSize, mode: mode))
    }
}
