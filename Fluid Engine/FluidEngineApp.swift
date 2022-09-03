import SwiftUI


@main
struct FluidEngineApp: App {
    
    // !!! = REMOVED CODE
    
        
    init() {
        Renderer.arch = .GPU
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

