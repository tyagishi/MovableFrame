//
//  FramedPhoto.swift
//  MovableFrame
//
//  Created by Tomoaki Yagishita on 2020/05/23.
//  Copyright © 2020 SmallDeskSoftware. All rights reserved.
//

import Foundation

class FramedPhoto: ObservableObject {
    @Published var frameRect: CGRect = CGRect(origin: CGPoint.zero, size: CGSize(width: 300, height: 200))
    @Published var canvasRect: CGRect = CGRect.zero
    
}
