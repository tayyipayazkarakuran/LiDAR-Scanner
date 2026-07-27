import ARKit
import RealityKit
import Metal
import Combine

class ARSessionManager: NSObject, ObservableObject {
    let session = ARSession()

    @Published var meshAnchors: [ARMeshAnchor] = []
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var isLiDARAvailable: Bool = false

    private var anchorSet = Set<UUID>()

    override init() {
        super.init()
        session.delegate = self
        checkLiDARSupport()
    }

    private func checkLiDARSupport() {
        let config = ARWorldTrackingConfiguration()
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)
    }

    func run() {
        guard isLiDARAvailable else { return }

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .none

        anchorSet.removeAll()
        meshAnchors.removeAll()

        session.run(config, options: [.resetSceneReconstruction, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }

    func stitchMesh() -> ScannedMesh {
        var mesh = ScannedMesh()
        for anchor in meshAnchors {
            mesh.append(anchor: anchor)
        }
        return mesh
    }

    func reset() {
        anchorSet.removeAll()
        meshAnchors.removeAll()
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for case let meshAnchor as ARMeshAnchor in anchors {
            if !anchorSet.contains(meshAnchor.identifier) {
                anchorSet.insert(meshAnchor.identifier)
                meshAnchors.append(meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for case let meshAnchor as ARMeshAnchor in anchors {
            if let index = meshAnchors.firstIndex(where: { $0.identifier == meshAnchor.identifier }) {
                meshAnchors[index] = meshAnchor
            } else {
                anchorSet.insert(meshAnchor.identifier)
                meshAnchors.append(meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for case let meshAnchor as ARMeshAnchor in anchors {
            anchorSet.remove(meshAnchor.identifier)
            meshAnchors.removeAll { $0.identifier == meshAnchor.identifier }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        trackingState = frame.camera.trackingState
    }

    func sessionWasInterrupted(_ session: ARSession) {
        trackingState = .limited(.relocalizing)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        trackingState = .normal
    }
}
