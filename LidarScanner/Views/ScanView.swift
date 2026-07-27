import SwiftUI
import ARKit
import RealityKit

struct ScanView: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        ZStack {
            if viewModel.isScanning {
                scannerView
            } else {
                startView
            }

            VStack {
                statusBar
                Spacer()
                controlButtons
            }
        }
        .ignoresSafeArea(.all, edges: .all)
    }

    private var startView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)

                Text("LiDAR Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Araç plastik parçalarınızı tarayın\nOBJ / STL / PLY olarak dışa aktarın")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                if !viewModel.isLiDARAvailable {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                        Text("Bu cihaz LiDAR desteklemiyor.\niPhone 12 Pro veya daha yeni bir model gereklidir.")
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private var scannerView: some View {
        ZStack {
            ARViewContainer(sessionManager: viewModel.sessionManager)
                .ignoresSafeArea()
        }
    }

    private var statusBar: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(viewModel.isScanning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(viewModel.trackingStateText)
                    .font(.caption)
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.vertexCount) vertex")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if viewModel.isScanning {
                Text("Nesnenin etrafında yavaşça dolaşın")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
    }

    private var controlButtons: some View {
        HStack(spacing: 40) {
            if !viewModel.isScanning {
                Button { viewModel.resetScan() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("Sıfırla")
                            .font(.caption)
                    }
                }
                .foregroundColor(.white)
                .disabled(viewModel.vertexCount == 0)
                .opacity(viewModel.vertexCount == 0 ? 0.3 : 1)

                Button { viewModel.startScanning() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.blue)
                            .clipShape(Circle())
                        Text("Taramayı Başlat")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .disabled(!viewModel.isLiDARAvailable)

                Button { viewModel.stopScanning() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                        Text("Dışa Aktar")
                            .font(.caption)
                    }
                }
                .foregroundColor(.white)
                .disabled(viewModel.vertexCount == 0)
                .opacity(viewModel.vertexCount == 0 ? 0.3 : 1)
            } else {
                Spacer()

                Button { viewModel.stopScanning() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.red)
                            .clipShape(Circle())
                        Text("Durdur")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ARViewContainer: UIViewRepresentable {
    let sessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        arView.session = sessionManager.session
        arView.automaticallyConfigureSession = false
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.renderOptions.insert(.disableGroundShadows)

        arView.environment.sceneUnderstanding.options = []

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
