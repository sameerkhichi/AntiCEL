import SwiftUI
import SceneKit

struct VehicleModel3DView: UIViewRepresentable {

    var selectedArea: VehicleArea?
    var onSelect: (VehicleArea) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        let background = UIColor.systemBackground
        view.scene = GenericSedanSceneBuilder.makeScene(backgroundColor: background)
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.minimumVerticalAngle = -10
        view.defaultCameraController.maximumVerticalAngle = 70
        view.backgroundColor = background
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true
        //no border / chrome — sits flush with the page
        view.layer.cornerRadius = 0
        view.clipsToBounds = true

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 42
        camera.camera?.wantsHDR = true
        camera.position = SCNVector3(3.4, 1.9, 4.0)
        camera.look(at: SCNVector3(0, 0.45, 0))
        view.pointOfView = camera
        view.scene?.rootNode.addChildNode(camera)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        context.coordinator.scnView = view
        context.coordinator.onSelect = onSelect

        applySelection(
            selectedArea,
            in: view,
            animated: false,
            coordinator: context.coordinator
        )

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onSelect = onSelect

        //keep scene background matched to light/dark mode
        let background = UIColor.systemBackground
        uiView.backgroundColor = background
        uiView.scene?.background.contents = background

        guard context.coordinator.lastSelectedArea != selectedArea else {
            return
        }

        applySelection(
            selectedArea,
            in: uiView,
            animated: true,
            coordinator: context.coordinator
        )
    }

    private func applySelection(
        _ area: VehicleArea?,
        in view: SCNView,
        animated: Bool,
        coordinator: Coordinator
    ) {
        coordinator.lastSelectedArea = area

        guard let sedan = view.scene?.rootNode.childNode(
            withName: GenericSedanSceneBuilder.sedanNodeName,
            recursively: false
        ) else {
            return
        }

        sedan.enumerateChildNodes { node, _ in
            guard let name = node.name,
                  VehicleArea(rawValue: name) != nil
            else {
                return
            }

            let isSelected = area.map { node.name == $0.rawValue } ?? true
            let opacity: CGFloat = {
                guard area != nil else { return 1 }
                return isSelected ? 1 : 0.38
            }()

            if animated {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.28
                node.opacity = opacity
                SCNTransaction.commit()
            } else {
                node.opacity = opacity
            }
        }

        let hoodPivot = sedan.childNode(withName: "hoodPivot", recursively: false)
        let trunkPivot = sedan.childNode(withName: "trunkPivot", recursively: false)

        let hoodAngle: Float = area == .drivetrain ? -0.55 : 0
        let trunkAngle: Float = area == .misc ? 0.7 : 0

        if animated {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.35
            hoodPivot?.eulerAngles.x = hoodAngle
            trunkPivot?.eulerAngles.x = trunkAngle
            SCNTransaction.commit()
        } else {
            hoodPivot?.eulerAngles.x = hoodAngle
            trunkPivot?.eulerAngles.x = trunkAngle
        }

        let wheelPivots = sedan.childNodes.filter { $0.name == VehicleArea.wheels.rawValue }
        for pivot in wheelPivots {
            pivot.removeAction(forKey: "spin")
            if area == .wheels {
                let spin = SCNAction.repeatForever(
                    SCNAction.rotateBy(x: CGFloat.pi * 2, y: 0, z: 0, duration: 1.15)
                )
                pivot.runAction(spin, forKey: "spin")
            }
        }
    }

    final class Coordinator: NSObject {
        var onSelect: (VehicleArea) -> Void
        var lastSelectedArea: VehicleArea?
        weak var scnView: SCNView?

        init(onSelect: @escaping (VehicleArea) -> Void) {
            self.onSelect = onSelect
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }

            let location = gesture.location(in: view)
            let hits = view.hitTest(
                location,
                options: [
                    .boundingBoxOnly: false,
                    .searchMode: SCNHitTestSearchMode.closest.rawValue
                ]
            )

            for hit in hits {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name,
                       let area = VehicleArea(rawValue: name) {
                        onSelect(area)
                        return
                    }
                    node = current.parent
                }
            }
        }
    }
}
