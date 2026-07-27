import Foundation

struct PLYExporter: MeshExporter {
    static func export(mesh: ScannedMesh, to url: URL) throws {
        try validate(mesh: mesh)

        var ply = "ply\n"
        ply += "format ascii 1.0\n"
        ply += "comment LidarScanner Export\n"
        ply += "comment \(Date())\n"
        ply += "element vertex \(mesh.vertexCount)\n"
        ply += "property float x\n"
        ply += "property float y\n"
        ply += "property float z\n"
        ply += "property float nx\n"
        ply += "property float ny\n"
        ply += "property float nz\n"
        ply += "element face \(mesh.triangleCount)\n"
        ply += "property list uchar int vertex_indices\n"
        ply += "end_header\n"

        let hasNormals = !mesh.normals.isEmpty
        for i in 0..<mesh.vertexCount {
            let v = mesh.vertices[i]
            if hasNormals {
                let n = mesh.normals[i]
                ply += "\(v.x) \(v.y) \(v.z) \(n.x) \(n.y) \(n.z)\n"
            } else {
                ply += "\(v.x) \(v.y) \(v.z) 0 0 0\n"
            }
        }

        for tri in mesh.triangles {
            ply += "3 \(tri.0) \(tri.1) \(tri.2)\n"
        }

        do {
            try ply.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.writeFailed(error)
        }
    }
}
