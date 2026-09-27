import SwiftUI

@main
struct LoudPhotoApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Capture", systemImage: "camera.fill") }

            GalleryView()
                .tabItem { Label("Library", systemImage: "square.grid.3x3.fill") }
        }
    }
}
