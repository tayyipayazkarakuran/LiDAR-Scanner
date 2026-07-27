import Foundation
import simd

struct STLExporter: MeshExporter {
    static func export(mesh: ScannedMesh, to url: URL) throws {
        try validate(mesh: mesh)

        let data = try exportData(mesh: mesh)

        do {
            try data.write(to: url)
        } catch {
            throw ExportError.writeFailed(error)
        }
    }

    static func exportData(mesh: ScannedMesh) throws -> Data {
        try validate(mesh: mesh)

        var data = Data()
        let header = "LidarScanner STL Export".padding(toLength: 80, withPad: "\0", startingAt: 0)
        data.append(header.data(using: .ascii)!)

        var triangleCount = UInt32(mesh.triangleCount)
        data.append(Data(bytes: &triangleCount, count: 4))

        for tri in mesh.triangles {
            let i0 = Int(tri.0)
            let i1 = Int(tri.1)
            let i2 = Int(tri.2)

            guard i0 < mesh.vertices.count,
                  i1 < mesh.vertices.count,
                  i2 < mesh.vertices.count else {
                throw ExportError.invalidData("Triangle index out of bounds")
            }

            let v0 = mesh.vertices[i0]
            let v1 = mesh.vertices[i1]
            let v2 = mesh.vertices[i2]

            let normal = calculateNormal(v0, v1, v2)
            appendVector(&data, normal)
            appendVector(&data, v0)
            appendVector(&data, v1)
            appendVector(&data, v2)

            var attribute: UInt16 = 0
            data.append(Data(bytes: &attribute, count: 2))
        }

        return data
    }

    private static func appendVector(_ data: inout Data, _ v: SIMD3<Float>) {
        var x = v.x
        var y = v.y
        var z = v.z
        data.append(Data(bytes: &x, count: 4))
        data.append(Data(bytes: &y, count: 4))
        data.append(Data(bytes: &z, count: 4))
    }

    private static func calculateNormal(
        _ v0: SIMD3<Float>,
        _ v1: SIMD3<Float>,
        _ v2: SIMD3<Float>
    ) -> SIMD3<Float> {
        let edge1 = v1 - v0
        let edge2 = v2 - v0
        let normal = simd_cross(edge1, edge2)
        let len: Float = simd_length(normal)
        return len > 0 ? normal / len : SIMD3<Float>(0, 1, 0)
    }
}
