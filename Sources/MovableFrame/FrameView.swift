//
//  FrameView.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/05/20.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import SwiftUI

public struct FrameView: View {
    public enum Anchor {
        case UpperLeft, UpperRight, LowerLeft, LowerRight
    }

    @Binding var frameRect: CGRect
    var canvasRect: CGRect
    @State private var isDragging:Bool = false
    @State private var dragStartRect: CGRect = CGRect.zero
    @State private var isHoveringOnCorner = false
    var cornerDragBoxSize = CGSize(width: 50, height: 50)

    public init(frameRect: Binding<CGRect>, canvasRect: CGRect) {
        self._frameRect = frameRect
        self.canvasRect = canvasRect
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .stroke(lineWidth: 3).foregroundColor(Color.red)
                .contentShape(Rectangle().inset(by: -10))
                .onHover(perform: { isIn in
                    if isHoveringOnCorner { return }
                    isIn ? NSCursor.openHand.set() : NSCursor.arrow.set()
                })
                .tlPlacement(rect: frameRect)
                .gesture(dragMoveGesture)
                .overlay(ExpandCorner(frameRect: $frameRect, isHovering: $isHoveringOnCorner, canvasRect: canvasRect,
                                      dragBoxSize: cornerDragBoxSize, fixedCorner: .LowerRight))
                .overlay(ExpandCorner(frameRect: $frameRect, isHovering: $isHoveringOnCorner, canvasRect: canvasRect,
                                      dragBoxSize: cornerDragBoxSize, fixedCorner: .LowerLeft))
                .overlay(ExpandCorner(frameRect: $frameRect, isHovering: $isHoveringOnCorner, canvasRect: canvasRect,
                                      dragBoxSize: cornerDragBoxSize, fixedCorner: .UpperRight))
                .overlay(ExpandCorner(frameRect: $frameRect, isHovering: $isHoveringOnCorner, canvasRect: canvasRect,
                                      dragBoxSize: cornerDragBoxSize, fixedCorner: .UpperLeft))
        }
    }

    var dragMoveGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if self.isDragging == false {
                    self.dragStartRect = self.frameRect
                    self.isDragging = true
                }

                let newPosition = CGPoint(x: gesture.translation.width + self.dragStartRect.origin.x,
                                          y: gesture.translation.height + self.dragStartRect.origin.y)
                let checkRect = CGRect(origin: newPosition, size: self.frameRect.size)
                if self.canvasRect.contains(checkRect) {
                    self.frameRect.origin = newPosition
                }
            }
            .onEnded { gesture in
                self.isDragging = false
                NSCursor.arrow.set()
            }
    }
}

extension CGRect {
    // return CGSize for .offset to place Rectangle
    func offsetForRect() -> CGSize {
        return CGSize(width: self.width/2, height: self.height/2)
    }
}


struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        FrameView(frameRect: .constant(CGRect.zero), canvasRect: CGRect(x: 0, y: 0, width: 800, height: 600))
    }
}

struct TopLeadingPlacement: ViewModifier {
    let rect: CGRect
    func body(content: Content) -> some View {
            content
                .frame(width: rect.size.width, height: rect.size.height)
//                .offset(x: rect.origin.x + rect.size.width/2, y: rect.origin.y + rect.size.height/2)
                .position(x: rect.origin.x + rect.size.width/2,
                          y: rect.origin.y + rect.size.height/2)
    }
}

extension View {
    func tlPlacement( rect: CGRect ) -> some View {
        self.modifier(TopLeadingPlacement(rect: rect))
    }
}
