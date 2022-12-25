//
//  LabeledHStack.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import SwiftUI

struct LabeledHStack<Content: View>: View {
    var label: String
    var content: () -> Content
    @State var labelWidth: CGFloat = 0

    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        HStack {
            Text(label)
                .readWidth { self.labelWidth = $0 }
            content()
        }
        .alignmentGuide(.leading) { _ in labelWidth + 10 } // see note
    }
}

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { }
}

extension View {
    func readWidth(onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: WidthPreferenceKey.self, value: geometryProxy.size.width)
            }
        )
        .onPreferenceChange(WidthPreferenceKey.self, perform: onChange)
    }
}
