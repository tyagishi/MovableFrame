//
//  FrameView.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/05/20.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import SwiftUI
import Combine

public let shiftIsChanged = NSNotification.Name("ShiftIsChanged")

public struct FrameView: View {
    public enum Anchor {
        case UpperLeft, UpperRight, LowerLeft, LowerRight
    }

    
    @Binding var frameRect: CGRect
    var canvasRect: CGRect
    var dragRect: CGRect
    var imageRect:CGRect  // rect in canvas(size)
    @State private var isDragging:Bool = false
    @State private var dragStartRect: CGRect = CGRect.zero
    @State private var isHoveringOnCorner = false
    var cornerDragBoxSize = CGSize(width: 50, height: 50)
    @State private var shouldFit:Bool = false
    let alignThreshold:CGFloat = 20

    public init(frameRect: Binding<CGRect>, canvasRect: CGRect, dragRect: CGRect = .zero, imageRect: CGRect = .zero) {
        self._frameRect = frameRect
        self.canvasRect = canvasRect
        self.dragRect = dragRect
        self.imageRect = imageRect
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
                //.simultaneousGesture(dragMoveGesture, including: .all)
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
        .onReceive(NotificationCenter.default.publisher(for: shiftIsChanged)) { obj in
            guard let bValue = obj.object as? Bool else { return }
            self.shouldFit = bValue
        }
    }

    var dragMoveGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if self.isDragging == false {
                    self.dragStartRect = self.frameRect
                    self.isDragging = true
                }

                var newPosition = CGPoint(x: gesture.translation.width + self.dragStartRect.origin.x,
                                          y: gesture.translation.height + self.dragStartRect.origin.y)
                if shouldFit {
                    // check top
                    let diffTop = abs( imageRect.minY - newPosition.y )
                    let diffBottom = abs( imageRect.maxY - (newPosition.y + frameRect.height) )
                    if diffTop < diffBottom {
                        // align to top?
                        if diffTop < alignThreshold {
                            newPosition.y = imageRect.minY
                        }
                    } else {
                        // align to bottom?
                        if diffBottom < alignThreshold {
                            newPosition.y = imageRect.maxY - frameRect.height
                        }
                    }

                    let diffLeft = abs( imageRect.minX - newPosition.x)
                    let diffRight = abs( imageRect.maxX - (newPosition.x + frameRect.width))
                    if diffLeft < diffRight {
                        // align to left?
                        if diffLeft < alignThreshold {
                            newPosition.x = imageRect.minX
                        }
                    } else {
                        if diffRight < alignThreshold {
                            newPosition.x = imageRect.maxX - frameRect.width
                        }
                    }
                }
                if dragRect != .zero {
                    let checkRect = CGRect(origin: newPosition, size: frameRect.size)
                    if !dragRect.contains(checkRect) { return }
                }
                self.frameRect.origin = newPosition
            }
            .onEnded { gesture in
                if shouldFit { return }
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

extension KeyEquivalent: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.character == rhs.character
    }
}

public typealias KeyInputSubject = PassthroughSubject<KeyEquivalent, Never>

public final class KeyInputSubjectWrapper: ObservableObject, Subject {
    public func send(_ value: Output) {
        objectWillChange.send(value)
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        objectWillChange.send(completion: completion)
    }
    
    public func send(subscription: Subscription) {
        objectWillChange.send(subscription: subscription)
    }
    

    public typealias ObjectWillChangePublisher = KeyInputSubject
    public let objectWillChange: ObjectWillChangePublisher
    public init(subject: ObjectWillChangePublisher = .init()) {
        objectWillChange = subject
    }
}

// MARK: Publisher Conformance
public extension KeyInputSubjectWrapper {
    typealias Output = KeyInputSubject.Output
    typealias Failure = KeyInputSubject.Failure
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        objectWillChange.receive(subscriber: subscriber)
    }
}
   
