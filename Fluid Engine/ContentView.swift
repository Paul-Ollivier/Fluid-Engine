//
//  ContentView.swift
//  vox.Force
//
//  Created by Feng Yang on 2020/7/23.
//  Copyright © 2020 Feng Yang. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let renderer = Renderer()
    
    var body: some View {
        MetalKitView(view: renderer)
            .frame(minWidth: 640, minHeight: 320)
    }
}
