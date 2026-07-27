import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case obj = "OBJ"
    case stl = "STL"
    case ply = "PLY"

    var id: String { rawValue }

    var fileExtension: String {
        rawValue.lowercased()
    }

    var mimeType: String {
        switch self {
        case .obj: return "model/obj"
        case .stl: return "model/stl"
        case .ply: return "model/ply"
        }
    }

    var description: String {
        switch self {
        case .obj: return "Wavefront OBJ"
        case .stl: return "Binary STL (3D Yazıcı)"
        case .ply: return "Stanford PLY"
        }
    }
}
