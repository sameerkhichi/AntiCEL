import SwiftUI
import SceneKit

struct VehicleModel3DView: UIViewRepresentable {

    var selectedArea: VehicleArea?
    var cameraResetID: UUID
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
        view.defaultCameraController.minimumVerticalAngle = -10
        view.defaultCameraController.maximumVerticalAngle = 70
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true

        let camera = SCNNode()
        camera.name = GenericSedanSceneBuilder.cameraNodeName
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 40
        camera.camera?.wantsHDR = true
        camera.position = GenericSedanSceneBuilder.defaultCameraPosition
        camera.look(at: GenericSedanSceneBuilder.defaultCameraTarget)
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
        context.coordinator.lastCameraResetID = cameraResetID

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
        uiView.backgroundColor = .clear
        uiView.isOpaque = false
        uiView.scene?.background.contents = UIColor.clear
        preferCameraControlOverScroll(in: uiView, coordinator: context.coordinator)

        if context.coordinator.lastCameraResetID != cameraResetID {
            context.coordinator.lastCameraResetID = cameraResetID
            resetCamera(in: uiView)
        }

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

    private func resetCamera(in view: SCNView) {
        guard let camera = view.pointOfView ?? view.scene?.rootNode.childNode(
            withName: GenericSedanSceneBuilder.cameraNodeName,
            recursively: true
        ) else {
            return
        }

        view.pointOfView = camera

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.35
        camera.position = GenericSedanSceneBuilder.defaultCameraPosition
        camera.eulerAngles = SCNVector3Zero
        camera.look(at: GenericSedanSceneBuilder.defaultCameraTarget)
        SCNTransaction.commit()
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

        let model = sedan.childNode(
            withName: GenericSedanSceneBuilder.modelNodeName,
            recursively: false
        )
        let hotspots = sedan.childNode(
            withName: GenericSedanSceneBuilder.hotspotsNodeName,
            recursively: false
        )

        //keep the USDZ model fully visible; tint hotspot overlays for feedback
        if animated {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
        }

        model?.opacity = 1

        hotspots?.enumerateChildNodes { node, _ in
            guard let name = node.name,
                  let part = VehicleArea(rawValue: name)
            else {
                return
            }

            if let area {
                let isSelected = part == area
                node.geometry?.firstMaterial?.diffuse.contents = isSelected
                    ? highlightColor(for: part)
                    : UIColor.clear
                node.opacity = isSelected ? 0.22 : 0.01
            } else {
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
                node.opacity = 0.01
            }
        }

        if animated {
            SCNTransaction.commit()
        }
    }

    private func highlightColor(for area: VehicleArea) -> UIColor {
        switch area {
        case .drivetrain: return UIColor.systemOrange
        case .body: return UIColor.systemBlue
        case .wheels: return UIColor.systemGreen
        case .misc: return UIColor.systemBrown
        }
    }

    final class Coordinator: NSObject {
        var onSelect: (VehicleArea) -> Void
        var lastSelectedArea: VehicleArea?
        var lastCameraResetID: UUID?
        var didBindScrollGestures = false
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
                    .searchMode: SCNHitTestSearchMode.all.rawValue,
                    .ignoreHiddenNodes: false
                ]
            )

            if let wheels = firstArea(in: hits, matching: .wheels) {
                onSelect(wheels)
                return
            }

            if let area = firstArea(in: hits) {
                onSelect(area)
            }
        }

        private func firstArea(
            in hits: [SCNHitTestResult],
            matching only: VehicleArea? = nil
        ) -> VehicleArea? {
            for hit in hits {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name,
                       let area = VehicleArea(rawValue: name) {
                        if let only {
                            if area == only { return area }
                        } else {
                            return area
                        }
                    }
                    node = current.parent
                }
            }
            return nil
        }
    }
}

private func preferCameraControlOverScroll(in view: SCNView, coordinator: VehicleModel3DView.Coordinator) {
    guard !coordinator.didBindScrollGestures else { return }

    DispatchQueue.main.async {
        guard let scrollView = view.enclosingScrollView() else { return }

        view.gestureRecognizers?
            .compactMap { $0 as? UIPanGestureRecognizer }
            .forEach { cameraPan in
                scrollView.panGestureRecognizer.require(toFail: cameraPan)
            }

        coordinator.didBindScrollGestures = true
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var current: UIView? = superview
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}
