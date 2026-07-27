import Foundation
import ARKit
import Metal

struct ScannedMesh {
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var triangles: [(UInt32, UInt32, UInt32)] = []

    var vertexCount: Int { vertices.count }
    var triangleCount: Int { triangles.count }

    init() {}

    init(from meshAnchors: [ARMeshAnchor]) {
        for anchor in meshAnchors {
            append(anchor: anchor)
        }
    }

    mutating func append(anchor: ARMeshAnchor) {
        let geometry = anchor.geometry
        let transform = anchor.transform
        let vertexCount = geometry.vertices.count

        let vertexPointer = geometry.vertices.buffer.contents()
            .advanced(by: geometry.vertices.offset)
            .assumingMemoryBound(to: SIMD3<Float>.self)

        let normalPointer = geometry.normals.buffer.contents()
            .advanced(by: geometry.normals.offset)
            .assumingMemoryBound(to: SIMD3<Float>.self)

        let facePointer = geometry.faces.buffer.contents()
            .assumingMemoryBound(to: UInt32.self)

        let faceCount = geometry.faces.count
        let faceIndexCountPerFace = 3

        let vertexOffset = UInt32(vertices.count)

        for i in 0..<vertexCount {
            let localVertex = vertexPointer[i]
            let worldVertex = transform * SIMD4<Float>(localVertex, 1)
            vertices.append(SIMD3<Float>(worldVertex.x, worldVertex.y, worldVertex.z))

            let localNormal = normalPointer[i]
            let rotationMatrix = simd_float3x3(
                SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
                SIMD3<Float>(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
                SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
            )
            let worldNormal = simd_mul(rotationMatrix, localNormal)
            normals.append(simd_normalize(worldNormal))
        }

        for i in 0..<faceCount {
            let offset = i * geometry.faces.bytesPerIndex * faceIndexCountPerFace
            let indices = facePointer.advanced(by: offset / MemoryLayout<UInt32>.size)
            let i0 = indices[0] + vertexOffset
            let i1 = indices[1] + vertexOffset
            let i2 = indices[2] + vertexOffset
            triangles.append((i0, i1, i2))
        }
    }

    mutating func append(mesh: ScannedMesh) {
        let offset = UInt32(vertices.count)
        vertices.append(contentsOf: mesh.vertices)
        normals.append(contentsOf: mesh.normals)
        for tri in mesh.triangles {
            triangles.append((tri.0 + offset, tri.1 + offset, tri.2 + offset))
        }
    }

    func estimatedFileSize(format: ExportFormat) -> UInt64 {
        let vertexSize = UInt64(vertices.count) * 36
        let faceDataSize: UInt64
        switch format {
        case .obj:
            faceDataSize = UInt64(triangles.count) * 30
            return 200 + vertexSize + faceDataSize
        case .stl:
            return 84 + UInt64(triangles.count) * 50
        case .ply:
            let headerSize: UInt64 = 200
            let perVertex = 72
            let perFace = 40
            return headerSize + UInt64(vertices.count) * UInt64(perVertex) + UInt64(triangles.count) * UInt64(perFace)
        }
    }
}

extension ScannedMesh: Equatable {
    static func == (lhs: ScannedMesh, rhs: ScannedMesh) -> Bool {
        lhs.vertices.count == rhs.vertices.count &&
        lhs.triangles.count == rhs.triangles.count
    }
}
        let faceDataSize: UInt64
        switch format {
        case .obj:
            faceDataSize = UInt64(triangles.count) * 30
            return 200 + vertexSize + faceDataSize
        case .stl:
            return 84 + UInt64(triangles.count) * 50
        case .ply:
            let headerSize: UInt64 = 200
            let perVertex = 72
            let perFace = 40
            return headerSize + UInt64(vertices.count) * UInt64(perVertex) + UInt64(triangles.count) * UInt64(perFace)
        }
    }
}
