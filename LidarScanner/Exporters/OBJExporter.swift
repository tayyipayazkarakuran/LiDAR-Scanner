import Foundation

struct OBJExporter: MeshExporter {
    static func export(mesh: ScannedMesh, to url: URL) throws {
        try validate(mesh: mesh)

        var obj = "# LidarScanner Export\n"
        obj += "# \(Date())\n"
        obj += "# Vertices: \(mesh.vertexCount)\n"
        obj += "# Faces: \(mesh.triangleCount)\n\n"

        for v in mesh.vertices {
            obj += "v \(v.x) \(v.y) \(v.z)\n"
        }

        if !mesh.normals.isEmpty {
            obj += "\n"
            for n in mesh.normals {
                obj += "vn \(n.x) \(n.y) \(n.z)\n"
            }
        }

        obj += "\n"
        for tri in mesh.triangles {
            let i0 = tri.0 + 1
            let i1 = tri.1 + 1
            let i2 = tri.2 + 1
            if !mesh.normals.isEmpty {
                obj += "f \(i0)//\(i0) \(i1)//\(i1) \(i2)//\(i2)\n"
            } else {
                obj += "f \(i0) \(i1) \(i2)\n"
            }
        }

        do {
            try obj.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.writeFailed(error)
        }
    }
}
