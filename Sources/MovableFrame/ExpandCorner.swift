//
//  ExpandCorner.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/06/08.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import SwiftUI

struct ExpandCorner: View {
    @Binding var frameRect: CGRect
    var canvasRect: CGRect
    @Binding var isHovering:Bool
    let dragBoxSize: CGSize
    let fixedCorner: FrameView.Anchor
    @State var isDraggingUL: Bool = false
    @State var dragStartRect: CGRect = CGRect.zero

    var body: some View {
        let dragCorner = ExpandCorner.oppositeCorner(corner: fixedCorner)
        let cornerCenter = ExpandCorner.cornerPosition(frame: frameRect, corner: dragCorner)
        let cornerCenterInSize = CGSize(width: cornerCenter.x - canvasRect.width / 2, height: cornerCenter.y - canvasRect.height / 2)
        return Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .frame(width: dragBoxSize.width, height: dragBoxSize.height)
            .onHover(perform: { isIn in
                isHovering = isIn
                print("isIn(ExpandCorner): \(isIn)")
//                isIn ? NSCursor.resizeUpDown.set() : NSCursor.arrow.set()
                isIn ? self.cursor() : NSCursor.arrow.set()
            })
            .border(Color.blue)
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
    
    func cursor() -> Void {
//        let cursorDir = "resizenortheastsouthwest"
//        let cursorFile = "cursor.pdf"
//        let baseURL = URL(fileURLWithPath: "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors")
//        let cursorBasePath = baseURL.appendingPathComponent(cursorDir)
//        let cursorImagePath = cursorBasePath.appendingPathComponent(cursorFile)
//        let cursorInfoPath = cursorBasePath.appendingPathComponent("info.plist")
//        let nsImage = NSImage(byReferencingFile: cursorImagePath.absoluteString)!
//        let cursorInfo = NSDictionary(contentsOfFile: cursorInfoPath.absoluteString)
//        let hotPoint = NSPoint(x: cursorInfo?.value(forKey: "hotx") as! Double, y: cursorInfo?.value(forKey: "hoty") as! Double)
//        let cursor = NSCursor.init(image: nsImage, hotSpot: hotPoint)
        let cursor = NSCursor(image: NSImage(byReferencingFile: "/System/Library/Frameworks/WebKit.framework/Versions/Current/Frameworks/WebCore.framework/Resources/northWestSouthEastResizeCursor.png")!, hotSpot: NSPoint(x: 8, y: 8))
        cursor.set()
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
        ExpandCorner(frameRect: .constant(CGRect.zero), canvasRect: CGRect(x: 0, y: 0, width: 800, height: 600), isHovering: .constant(false),
                     dragBoxSize: CGSize(width: 10, height: 10), fixedCorner: .LowerLeft)
    }
}
