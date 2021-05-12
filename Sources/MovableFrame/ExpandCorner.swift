//
//  ExpandCorner.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/06/08.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import Foundation
import SwiftUI
import SDSCGExtension

struct ExpandCorner: View {
    @Binding var frameRect: CGRect
    @Binding var isHovering:Bool
    var canvasRect: CGRect
    let dragBoxSize: CGSize
    let fixedCorner: FrameView.Anchor
    @State var isDragging: Bool = false
    @State var dragStartRect: CGRect = CGRect.zero
    
    var shouldFit:Bool
    let alignThreshold:CGFloat = 50

    var body: some View {
        let dragCorner = ExpandCorner.oppositeCorner(corner: fixedCorner)
        let cornerCenter = ExpandCorner.cornerPosition(frame: frameRect, corner: dragCorner)
        let cornerBoxRect = CGRect(origin: CGPoint(x: cornerCenter.x - dragBoxSize.width/2, y: cornerCenter.y - dragBoxSize.width/2), size: dragBoxSize)
        return ZStack {
            Rectangle()
                .fill(Color.clear)
                //.border(Color.green) // for debug
                .contentShape(Rectangle())
                .frame(width: dragBoxSize.width, height: dragBoxSize.height)
                .onHover(perform: { isIn in
                    isHovering = isIn
                    isIn ? self.setCursor() : NSCursor.pop()
                })
                .tlPlacement(rect: cornerBoxRect)
                .gesture(DragGesture()
                            .onChanged { gesture in
                                if self.isDragging == false {
                                    self.dragStartRect = self.frameRect
                                    self.isDragging = true
                                }
                                // change size
                                let moveSize = ExpandCorner.getMoveSize(rect: self.frameRect.size, translation: gesture.translation, fixedCorner: self.fixedCorner)
                                var newFrameRect = ExpandCorner.changeSizeWithFixedCorner( rect: self.dragStartRect, moveInX: moveSize, anchor: self.fixedCorner)
                                if shouldFit {
                                    let rightDiff = abs( newFrameRect.maxX - canvasRect.maxX )
                                    let leftDiff = abs( newFrameRect.minX - canvasRect.minX )
                                    let topDiff = abs( newFrameRect.minY - canvasRect.minY )
                                    let bottomDiff = abs( newFrameRect.maxY - canvasRect.maxY )
                                    
                                    switch fixedCorner {
                                        case .UpperLeft: // check bottom-right
                                            if rightDiff < bottomDiff {
                                                if rightDiff < alignThreshold {
                                                    let newWidth = canvasRect.maxX - newFrameRect.minX
                                                    newFrameRect = newFrameRect.moveBottomRightCornerToNewWidthKeepingSizeRatio(newWidth)
                                                }
                                            } else {
                                                if bottomDiff < alignThreshold {
                                                    let newHeight = canvasRect.maxY - newFrameRect.minY
                                                    newFrameRect = newFrameRect.moveBottomRightCornerToNewHeightKeepingSizeRatio(newHeight)
                                                }
                                            }
                                        case .UpperRight:// check bottom-left
                                            if leftDiff < bottomDiff {
                                                if leftDiff < alignThreshold {
                                                    let newWidth = newFrameRect.maxX - canvasRect.minX
                                                    newFrameRect = newFrameRect.moveBottomLeftCornerToNewWidthKeepingSizeRatio(newWidth)
                                                }
                                            } else {
                                                if bottomDiff < alignThreshold {
                                                    let newHeight = canvasRect.maxY - newFrameRect.minY
                                                    newFrameRect = newFrameRect.moveBottomLeftCornerToNewHeightKeepingSizeRatio(newHeight)
                                                }
                                            }
                                        case .LowerLeft: // check upper right
                                            if rightDiff < topDiff {
                                                if rightDiff < alignThreshold {
                                                    let newWidth = canvasRect.maxX - newFrameRect.minX
                                                    newFrameRect = newFrameRect.moveUpperRightCornerToNewWidthKeepingSizeRatio(newWidth)
                                                }
                                            } else {
                                                if topDiff < alignThreshold {
                                                    let newHeight = newFrameRect.maxY - canvasRect.minY
                                                    newFrameRect = newFrameRect.moveUpperRightCornerToNewHeightKeepingSizeRatio(newHeight)
                                                }
                                            }
                                        case .LowerRight: // check upper left
                                            if leftDiff < topDiff {
                                                if leftDiff < alignThreshold {
                                                    let newWidth = newFrameRect.maxX - canvasRect.minX
                                                    newFrameRect = newFrameRect.moveUpperLeftCornerToNewWidthKeepingSizeRatio(newWidth)
                                                }
                                            } else {
                                                if topDiff < alignThreshold {
                                                    let newHeight = newFrameRect.maxY - canvasRect.minY
                                                    newFrameRect = newFrameRect.moveUpperLeftCornerToNewHeightKeepingSizeRatio(newHeight)
                                                }
                                            }
                                        //default:
                                        //    break
                                    }
                                }
                                //                    if self.canvasRect.contains(checkRect) {
                                self.frameRect = newFrameRect
                                //                    }
                            }
                            .onEnded { gesture in
                                self.isDragging = false
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
                     dragBoxSize: CGSize(width: 10, height: 10), fixedCorner: .LowerLeft, shouldFit: false)
    }
}
