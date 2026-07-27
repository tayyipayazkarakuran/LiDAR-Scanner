import SwiftUI
import RealityKit

struct MeshPreviewView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showExportView = false

    var body: some View {
        NavigationStack {
            VStack {
                if let mesh = viewModel.scannedMesh {
                    meshPreviewContent(mesh: mesh)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Mesh Önizleme")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.scannedMesh != nil {
                        Button("Dışa Aktar") {
                            showExportView = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportView) {
                ExportView(viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("Henüz tarama yapılmadı")
                .font(.title2)
                .foregroundColor(.gray)

            Text("Tarama sekmesine gidip bir nesne tarayın")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private func meshPreviewContent(mesh: ScannedMesh) -> some View {
        VStack(spacing: 16) {
            MeshPreviewContainer(mesh: mesh)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .padding()

            meshInfo(mesh: mesh)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    private func meshInfo(mesh: ScannedMesh) -> some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Text("\(mesh.vertexCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Vertex")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                Text("\(mesh.triangleCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Triangle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                Text(formatSize(mesh.estimatedFileSize(format: .stl)))
                    .font(.title3)
                    .fontWeight(.bold)
                Text("STL Boyut")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatSize(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

struct MeshPreviewContainer: UIViewRepresentable {
    let mesh: ScannedMesh

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)

        let meshResource = createMeshResource()
        if let meshResource {
            let entity = ModelEntity(mesh: meshResource)
            entity.model?.materials = [SimpleMaterial(color: .lightGray, isMetallic: false)]

            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            centerCamera(arView: arView, entity: entity)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func createMeshResource() -> MeshResource? {
        let vertexCount = mesh.vertices.count
        let triangleCount = mesh.triangles.count
        guard vertexCount > 0, triangleCount > 0 else { return nil }

        var positions: [SIMD3<Float>] = mesh.vertices
        var indices: [UInt32] = []
        indices.reserveCapacity(triangleCount * 3)
        for tri in mesh.triangles {
            indices.append(tri.0)
            indices.append(tri.1)
            indices.append(tri.2)
        }

        let center = mesh.vertices.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 } / Float(vertexCount)
        positions = positions.map { $0 - center }

        var descriptor = MeshDescriptor(name: "scanned")
        descriptor.positions = MeshBuffer(positions)
        descriptor.primitives = .triangles(indices)

        if !mesh.normals.isEmpty {
            descriptor.normals = MeshBuffer(mesh.normals)
        }

        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            return nil
        }
    }

    private func centerCamera(arView: ARView, entity: Entity) {
        let bounds = entity.visualBounds(relativeTo: nil)
        let size = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
        let distance: Float = size * 2.5

        let cameraPosition = SIMD3<Float>(0, bounds.center.y, distance)
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 60
        camera.look(at: bounds.center, from: cameraPosition, upVector: SIMD3<Float>(0, 1, 0), relativeTo: nil)
        let cameraAnchor = AnchorEntity(world: cameraPosition)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)
    }
}
