import SwiftUI

struct ContentView: View {
    @StateObject private var scanViewModel = ScanViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView(viewModel: scanViewModel)
                .tabItem {
                    Label("Tarama", systemImage: "camera.viewfinder")
                }
                .tag(0)

            MeshPreviewView(viewModel: scanViewModel)
                .tabItem {
                    Label("Önizleme", systemImage: "cube.transparent")
                }
                .tag(1)
        }
        .onChange(of: scanViewModel.scannedMesh) { _, newValue in
            if newValue != nil {
                selectedTab = 1
            }
        }
    }
}
