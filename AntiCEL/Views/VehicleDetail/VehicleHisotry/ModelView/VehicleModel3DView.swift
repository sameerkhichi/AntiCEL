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
        view.scene = GenericSedanSceneBuilder.makeScene()
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.minimumVerticalAngle = -15
        view.defaultCameraController.maximumVerticalAngle = 75
        view.backgroundColor = .secondarySystemBackground
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true

        //starting camera — 3/4 view of a blank sedan
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 45
        camera.position = SCNVector3(3.6, 2.2, 4.2)
        camera.look(at: SCNVector3(0, 0.5, 0))
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
                  let part = VehicleArea(rawValue: name),
                  let materials = node.geometry?.materials
            else {
                return
            }

            let isSelected = area == part
            let emission: UIColor = {
                guard isSelected else { return .clear }
                switch part {
                case .drivetrain: return UIColor.systemOrange.withAlphaComponent(0.55)
                case .body: return UIColor.systemBlue.withAlphaComponent(0.4)
                case .wheels: return UIColor.systemGreen.withAlphaComponent(0.45)
                case .misc: return UIColor.systemBrown.withAlphaComponent(0.5)
                }
            }()

            for material in materials {
                material.emission.contents = emission
            }

            let opacity: CGFloat = {
                guard let area else { return 1 }
                return isSelected ? 1 : 0.45
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

        let wheelNodes = sedan.childNodes.filter { $0.name == VehicleArea.wheels.rawValue }
        for wheel in wheelNodes {
            wheel.removeAction(forKey: "spin")
            if area == .wheels {
                //cylinder axle is local X after the 90° Z lay-down
                let spin = SCNAction.repeatForever(
                    SCNAction.rotateBy(x: CGFloat.pi * 2, y: 0, z: 0, duration: 1.1)
                )
                wheel.runAction(spin, forKey: "spin")
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
