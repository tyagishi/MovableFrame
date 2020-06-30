//
//  ExpandCorner.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/06/08.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpandCorner: View {
    @Binding var frameRect: CGRect
    @Binding var isHovering:Bool
    var canvasRect: CGRect
    let dragBoxSize: CGSize
    let fixedCorner: FrameView.Anchor
    @State var isDraggingUL: Bool = false
    @State var dragStartRect: CGRect = CGRect.zero

    var body: some View {
        let dragCorner = ExpandCorner.oppositeCorner(corner: fixedCorner)
        let cornerCenter = ExpandCorner.cornerPosition(frame: frameRect, corner: dragCorner)
        let cornerCenterInSize = CGSize(width: cornerCenter.x - canvasRect.width / 2 - canvasRect.origin.x,
                                        height: cornerCenter.y - canvasRect.height / 2 - canvasRect.origin.y)
        return ZStack {
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: cornerCenter.x, y: cornerCenter.y)
                //.offset(cornerCenterInSize)
            Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .frame(width: dragBoxSize.width, height: dragBoxSize.height)
            .onHover(perform: { isIn in
                isHovering = isIn
                isIn ? self.setCursor() : NSCursor.pop()
            })
            .offset(cornerCenterInSize)
            .gesture(DragGesture()
                .onChanged { gesture in
                    if self.isDraggingUL == false {
                        self.dragStartRect = self.frameRect
                        self.isDraggingUL = true
                    }
                    // change size
                    let moveSize = ExpandCorner.getMoveSize(rect: self.frameRect.size, translation: gesture.translation, fixedCorner: self.fixedCorner)
                    let checkRect = ExpandCorner.changeSizeWithFixedCorner( rect: self.dragStartRect, moveInX: moveSize, anchor: self.fixedCorner)
                    if self.canvasRect.contains(checkRect) {
                        self.frameRect = checkRect
                    }
                }
                .onEnded { gesture in
                    self.isDraggingUL = false
                    NSCursor.arrow.set()
                })
            
        }
    }
    
    func setCursor() -> Void {
        switch fixedCorner {
        case .UpperRight, .LowerLeft:
            guard let cursorImage = Bundle.module.image(forResource: "URLL") else { return }
            let cursor = NSCursor(image: cursorImage, hotSpot: NSPoint(x: 10.0, y: 10.0))
            cursor.push()
        case .UpperLeft, .LowerRight:
            guard let cursorImage = Bundle.module.image(forResource: "ULLR") else { return }
            let cursor = NSCursor(image: cursorImage, hotSpot: NSPoint(x: 10.0, y: 10.0))
            cursor.push()
        }
    }
    
    static func oppositeCorner(corner: FrameView.Anchor) -> FrameView.Anchor {
        switch corner {
        case .UpperLeft:
            return .LowerRight
        case .UpperRight:
            return .LowerLeft
        case .LowerLeft:
            return .UpperRight
        case .LowerRight:
            return .UpperLeft
        }
    }
    
    static func cornerPosition(frame: CGRect, corner: FrameView.Anchor) -> CGPoint {
        switch corner {
        case .UpperLeft:
            print("UpperLeft \(frame.minX) : \(frame.minY)")
            return CGPoint(x: frame.minX, y: frame.minY)
        case .UpperRight:
            return CGPoint(x: frame.maxX, y: frame.minY)
        case .LowerLeft:
            return CGPoint(x: frame.minX, y: frame.maxY)
        case .LowerRight:
            return CGPoint(x: frame.maxX, y: frame.maxY)
        }
    }

    public static func getMoveSize(rect: CGSize, translation: CGSize, fixedCorner: FrameView.Anchor) -> CGFloat {
        let yDivX = rect.height / rect.width
        let x = translation.width
        let y = translation.height * yDivX

        var moveSize:CGFloat = 0
        switch fixedCorner {
        case .LowerRight:
            moveSize = abs(x) > abs(y) ? x * -1 : y * -1 // moveSize   +: expand   -: schrink
        case .LowerLeft:
            moveSize = abs(x) > abs(y) ? x * +1 : y * -1 // moveSize   +: expand   -: schrink
        case .UpperRight:
            moveSize = abs(x) > abs(y) ? x * -1 : y * +1 // moveSize   +: expand   -: schrink
        case .UpperLeft:
            moveSize = abs(x) > abs(y) ? x * +1 : y * +1 // moveSize   +: expand   -: schrink
        }
        return moveSize
    }
    public  static func changeSizeWithFixedCorner( rect: CGRect, moveInX: CGFloat, anchor: FrameView.Anchor) -> CGRect {
        let yDivX =  rect.size.height / rect.size.width
        let changeInX = moveInX
        let changeInY = (yDivX*moveInX)

        //    origin
        //   (A)--------(B)
        //    |          |
        //    |          |
        //    |          |
        //    |          |
        //   (C)--------(D)
        if anchor == .LowerRight {
            // keep D
            let newSize = CGSize(width: rect.size.width + changeInX, height: rect.size.height + changeInY)
            let newOrigin = CGPoint(x: rect.origin.x - changeInX, y: rect.origin.y - changeInY)
            return CGRect(origin: newOrigin, size: newSize)
        }
        if anchor == .LowerLeft {
            // keep C
            let newSize = CGSize(width: rect.size.width + changeInX, height: rect.size.height + changeInY)
            let newOrigin = CGPoint(x: rect.origin.x, y: rect.origin.y - changeInY)
            return CGRect(origin: newOrigin, size: newSize)
        }
        if anchor == .UpperRight {
            // keep B
            let newSize = CGSize(width: rect.size.width + changeInX, height: rect.size.height + changeInY)
            let newOrigin = CGPoint(x: rect.origin.x - changeInX, y: rect.origin.y)
            return CGRect(origin: newOrigin, size: newSize)
        }
        if anchor == .UpperLeft {
            // keep A
            let newSize = CGSize(width: rect.size.width + changeInX, height: rect.size.height + changeInY)
            let newOrigin = CGPoint(x: rect.origin.x, y: rect.origin.y)
            return CGRect(origin: newOrigin, size: newSize)
        }
        return CGRect(origin: CGPoint.zero, size: CGSize.zero)
    }
}

struct ExpandCorner_Previews: PreviewProvider {
    static var previews: some View {
        ExpandCorner(frameRect: .constant(CGRect.zero), isHovering: .constant(false), canvasRect: CGRect(x: 0, y: 0, width: 800, height: 600),
                     dragBoxSize: CGSize(width: 10, height: 10), fixedCorner: .LowerLeft)
    }
}
