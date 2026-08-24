import Foundation
import Observation
import SceneKit

@MainActor
@Observable
final class VehicleSceneCache {
    static let shared = VehicleSceneCache()

    private(set) var isReady = false

    private var template: SCNScene?
    private var inFlight: Task<SCNScene, Never>?

    private init() {}

    func prepare() async {
        _ = await templateScene()
    }

    func clonedScene() -> SCNScene? {
        guard let template else { return nil }
        return GenericSedanSceneBuilder.clonedScene(from: template)
    }

    private func templateScene() async -> SCNScene {
        if let template {
            return template
        }

        if let inFlight {
            return await inFlight.value
        }

        let task = Task { await Self.loadTemplate() }
        inFlight = task
        let scene = await task.value
        template = scene
        isReady = true
        inFlight = nil
        return scene
    }

    nonisolated private static func loadTemplate() async -> SCNScene {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let model = GenericSedanSceneBuilder.preloadCarModel()
                DispatchQueue.main.async {
                    continuation.resume(
                        returning: GenericSedanSceneBuilder.buildTemplateScene(model: model)
                    )
                }
            }
        }
    }
}
