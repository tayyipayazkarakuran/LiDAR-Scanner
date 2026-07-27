import SwiftUI
import ARKit
import Combine

class ScanViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var scannedMesh: ScannedMesh?
    @Published var trackingStateText = "Hazır"
    @Published var vertexCount = 0
    @Published var isLiDARAvailable = false
    @Published var showExportSheet = false
    @Published var exportURL: URL?

    let sessionManager = ARSessionManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        sessionManager.$trackingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.trackingStateText = Self.description(for: state)
            }
            .store(in: &cancellables)

        sessionManager.$meshAnchors
            .receive(on: DispatchQueue.main)
            .sink { [weak self] anchors in
                let total = anchors.reduce(0) { $0 + $1.geometry.vertices.count }
                self?.vertexCount = total
            }
            .store(in: &cancellables)

        sessionManager.$isLiDARAvailable
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLiDARAvailable)
    }

    func startScanning() {
        scannedMesh = nil
        sessionManager.run()
        isScanning = true
    }

    func stopScanning() {
        sessionManager.stop()
        isScanning = false
        scannedMesh = sessionManager.stitchMesh()
    }

    func resetScan() {
        sessionManager.reset()
        scannedMesh = nil
        vertexCount = 0
        trackingStateText = "Hazır"
    }

    func exportMesh(format: ExportFormat) {
        guard let mesh = scannedMesh else { return }

        let fileName = "Scan_\(formattedDate()).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            switch format {
            case .obj:
                try OBJExporter.export(mesh: mesh, to: tempURL)
            case .stl:
                try STLExporter.export(mesh: mesh, to: tempURL)
            case .ply:
                try PLYExporter.export(mesh: mesh, to: tempURL)
            }
            exportURL = tempURL
            showExportSheet = true
        } catch {
            print("Export hatası: \(error.localizedDescription)")
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private static func description(for state: ARCamera.TrackingState) -> String {
        switch state {
        case .normal: return "İzleme: Normal"
        case .notAvailable: return "İzleme: Kullanılamıyor"
        case .limited(.initializing): return "İzleme: Başlatılıyor..."
        case .limited(.relocalizing): return "İzleme: Konumlanıyor..."
        case .limited(.excessiveMotion): return "İzleme: Çok fazla hareket"
        case .limited(.insufficientFeatures): return "İzleme: Yetersiz özellik"
        default: return "İzleme: Sınırlı"
        }
    }
}
