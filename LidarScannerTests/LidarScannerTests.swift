import XCTest
@testable import LidarScanner

final class LidarScannerTests: XCTestCase {
    func testEmptyMesh() {
        let mesh = ScannedMesh()
        XCTAssertEqual(mesh.vertexCount, 0)
        XCTAssertEqual(mesh.triangleCount, 0)
    }

    func testAppendMesh() {
        var mesh = ScannedMesh()
        mesh.vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        mesh.normals = [
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1)
        ]
        mesh.triangles = [(0, 1, 2)]

        var combined = ScannedMesh()
        combined.append(mesh: mesh)
        XCTAssertEqual(combined.vertexCount, 3)
        XCTAssertEqual(combined.triangleCount, 1)

        combined.append(mesh: mesh)
        XCTAssertEqual(combined.vertexCount, 6)
        XCTAssertEqual(combined.triangleCount, 2)
        XCTAssertEqual(combined.triangles[1].0, 3)
        XCTAssertEqual(combined.triangles[1].1, 4)
        XCTAssertEqual(combined.triangles[1].2, 5)
    }

    func testEstimatedFileSize() {
        var mesh = ScannedMesh()
        for _ in 0..<100 {
            mesh.vertices.append(SIMD3<Float>(0, 0, 0))
            mesh.normals.append(SIMD3<Float>(0, 0, 1))
        }
        for _ in 0..<50 {
            mesh.triangles.append((0, 1, 2))
        }

        let stlSize = mesh.estimatedFileSize(format: .stl)
        let expectedSize = 84 + 50 * 50
        XCTAssertEqual(stlSize, UInt64(expectedSize))
    }
}

final class OBJExporterTests: XCTestCase {
    func testExportSingleTriangle() throws {
        var mesh = ScannedMesh()
        mesh.vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        mesh.triangles = [(0, 1, 2)]

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.obj")

        try OBJExporter.export(mesh: mesh, to: tempURL)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertTrue(content.hasPrefix("# LidarScanner Export"))
        XCTAssertTrue(content.contains("v 0.0 0.0 0.0"))
        XCTAssertTrue(content.contains("v 1.0 0.0 0.0"))
        XCTAssertTrue(content.contains("v 0.0 1.0 0.0"))
        XCTAssertTrue(content.contains("f 1 2 3"))

        try FileManager.default.removeItem(at: tempURL)
    }

    func testExportWithNormals() throws {
        var mesh = ScannedMesh()
        mesh.vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        mesh.normals = [
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1)
        ]
        mesh.triangles = [(0, 1, 2)]

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_normals.obj")

        try OBJExporter.export(mesh: mesh, to: tempURL)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertTrue(content.contains("vn 0.0 0.0 1.0"))
        XCTAssertTrue(content.contains("f 1//1 2//2 3//3"))

        try FileManager.default.removeItem(at: tempURL)
    }

    func testExportEmptyMesh() {
        let mesh = ScannedMesh()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty.obj")

        XCTAssertThrowsError(try OBJExporter.export(mesh: mesh, to: tempURL)) { error in
            XCTAssertTrue(error is ExportError)
        }
    }
}

final class STLExporterTests: XCTestCase {
    func testExportSingleTriangle() throws {
        var mesh = ScannedMesh()
        mesh.vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        mesh.triangles = [(0, 1, 2)]

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.stl")

        try STLExporter.export(mesh: mesh, to: tempURL)

        let data = try Data(contentsOf: tempURL)
        XCTAssertEqual(data.count, 134)

        let header = data.prefix(80)
        let headerStr = String(data: header, encoding: .ascii)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        XCTAssertEqual(headerStr, "LidarScanner STL Export")

        let countData = data.subdata(in: 80..<84)
        let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }
        XCTAssertEqual(count, 1)

        try FileManager.default.removeItem(at: tempURL)
    }

    func testExportEmptyMesh() {
        let mesh = ScannedMesh()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty.stl")

        XCTAssertThrowsError(try STLExporter.export(mesh: mesh, to: tempURL)) { error in
            XCTAssertTrue(error is ExportError)
        }
    }
}

final class PLYExporterTests: XCTestCase {
    func testExportSingleTriangle() throws {
        var mesh = ScannedMesh()
        mesh.vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        mesh.normals = [
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1)
        ]
        mesh.triangles = [(0, 1, 2)]

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.ply")

        try PLYExporter.export(mesh: mesh, to: tempURL)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertTrue(content.hasPrefix("ply"))
        XCTAssertTrue(content.contains("element vertex 3"))
        XCTAssertTrue(content.contains("element face 1"))
        XCTAssertTrue(content.contains("end_header"))
        XCTAssertTrue(content.contains("3 0 1 2"))

        try FileManager.default.removeItem(at: tempURL)
    }

    func testExportEmptyMesh() {
        let mesh = ScannedMesh()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty.ply")

        XCTAssertThrowsError(try PLYExporter.export(mesh: mesh, to: tempURL)) { error in
            XCTAssertTrue(error is ExportError)
        }
    }
}
