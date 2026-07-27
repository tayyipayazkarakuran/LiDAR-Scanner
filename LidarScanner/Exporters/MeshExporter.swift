import Foundation

protocol MeshExporter {
    static func export(mesh: ScannedMesh, to url: URL) throws
}

extension MeshExporter {
    static func validate(mesh: ScannedMesh) throws {
        guard !mesh.vertices.isEmpty else {
            throw ExportError.noVertices
        }
        guard !mesh.triangles.isEmpty else {
            throw ExportError.noTriangles
        }
    }
}

enum ExportError: LocalizedError {
    case noVertices
    case noTriangles
    case writeFailed(Error)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .noVertices:
            return "Export için vertex verisi bulunamadı."
        case .noTriangles:
            return "Export için triangle verisi bulunamadı."
        case .writeFailed(let error):
            return "Dosya yazma hatası: \(error.localizedDescription)"
        case .invalidData(let detail):
            return "Geçersiz veri: \(detail)"
        }
    }
}
