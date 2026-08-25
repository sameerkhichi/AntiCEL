import SceneKit
import UIKit

/// Loads the bundled generic sedan USDZ and attaches invisible tap zones.
///
/// "Generic Sedan Car" (https://skfb.ly/oIOJC) by MMC Works is licensed under
/// Creative Commons Attribution 4.0 (https://creativecommons.org/licenses/by/4.0/).
/// Adapted for AntiCEL (USDZ conversion, tap zones, and part animation).
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"
    static let cameraNodeName = "mainCamera"
    static let modelNodeName = "carModel"
    static let hotspotsNodeName = "hotspots"

    static let defaultCameraPosition = SCNVector3(3.8, 2.0, 4.6)
    static let defaultCameraTarget = SCNVector3(0, 0.6, 0)
    static let overheadCameraPosition = SCNVector3(0, 7.6, 0)
    static let overheadCameraTarget = SCNVector3(0, 0.6, 0)
    static let overheadCameraUp = SCNVector3(0, 0, 1)

    static let engineBayCameraPosition = SCNVector3(0.2, 1.55, 3.85)
    static let engineBayCameraTarget = SCNVector3(0, 0.7, 1.4)

    static let trunkInteriorCameraPosition = SCNVector3(0.1, 1.15, -3.95)
    static let trunkInteriorCameraTarget = SCNVector3(0, 0.7, -0.45)

    static let passengerRearWheelCameraPosition = SCNVector3(2.55, 0.38, -1.3)
    static let passengerRearWheelCameraTarget = SCNVector3(0.95, 0.38, -1.3)
    static let passengerRearWheelCameraUp = SCNVector3(0, 1, 0)

    static let chassisCameraPosition = SCNVector3(-1.85, 0.05, -2.45)
    static let chassisCameraTarget = SCNVector3(0.25, 0.32, 0.7)
    static let chassisCameraUp = SCNVector3(0, 1, 0)

    static let interiorCameraPosition = SCNVector3(0, 0.98, -0.45)
    static let interiorCameraTarget = SCNVector3(0, 0.92, 0.65)

    static let hoodOpenRadians: Float = -45 * .pi / 180
    static let trunkOpenRadians: Float = 60 * .pi / 180
    static let wheelSpinActionKey = "wheelSpin"

    struct CameraFrame {
        var position: SCNVector3
        var target: SCNVector3
        var up: SCNVector3?
        var fieldOfView: CGFloat
    }

    static func cameraFrame(for area: VehicleArea?) -> CameraFrame {
        switch area {
        case .drivetrain:
            return CameraFrame(
                position: engineBayCameraPosition,
                target: engineBayCameraTarget,
                up: nil,
                fieldOfView: 36
            )
        case .misc:
            return CameraFrame(
                position: trunkInteriorCameraPosition,
                target: trunkInteriorCameraTarget,
                up: nil,
                fieldOfView: 36
            )
        case .wheels:
            return CameraFrame(
                position: passengerRearWheelCameraPosition,
                target: passengerRearWheelCameraTarget,
                up: passengerRearWheelCameraUp,
                fieldOfView: 28
            )
        case .chassis:
            return CameraFrame(
                position: chassisCameraPosition,
                target: chassisCameraTarget,
                up: chassisCameraUp,
                fieldOfView: 36
            )
        case .interior:
            return CameraFrame(
                position: interiorCameraPosition,
                target: interiorCameraTarget,
                up: nil,
                fieldOfView: 48
            )
        case .body:
            return CameraFrame(
                position: overheadCameraPosition,
                target: overheadCameraTarget,
                up: overheadCameraUp,
                fieldOfView: 40
            )
        case nil:
            return CameraFrame(
                position: defaultCameraPosition,
                target: defaultCameraTarget,
                up: nil,
                fieldOfView: 40
            )
        }
    }

    private static let modelResourceName = "Generic_Sedan_Car"

    static func preloadCarModel() -> SCNNode? {
        loadCarModel()
    }

    static func buildTemplateScene(model: SCNNode? = nil) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let sedan = SCNNode()
        sedan.name = sedanNodeName

        if let model = model ?? loadCarModel() {
            model.name = modelNodeName
            normalize(model, into: sedan)
            restoreBodyPaint(on: model)
            addHotspots(to: sedan, around: model)
        } else {
            //fallback placeholder if the asset is missing from the bundle
            let placeholder = SCNBox(width: 4.2, height: 1.2, length: 1.8, chamferRadius: 0.2)
            placeholder.firstMaterial?.diffuse.contents = UIColor.darkGray
            let node = SCNNode(geometry: placeholder)
            node.position.y = 0.6
            node.name = VehicleArea.body.rawValue
            sedan.addChildNode(node)
        }

        scene.rootNode.addChildNode(sedan)
        addLighting(to: scene)
        return scene
    }

    static func clonedScene(from template: SCNScene) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        for child in template.rootNode.childNodes {
            scene.rootNode.addChildNode(child.clone())
        }
        return scene
    }

    // MARK: - Animated parts

    static func hoodNode(in model: SCNNode) -> SCNNode? {
        rootMost(
            of: namedNodes(in: model) { name in
                name.contains("hood") && !name.contains("windshield")
            }
        ).first
    }

    static func trunkNode(in model: SCNNode) -> SCNNode? {
        rootMost(
            of: namedNodes(in: model) { name in
                name.contains("trunk") && !name.contains("light") && !name.contains("tail")
            }
        ).first
    }

    static func wheelNodes(in model: SCNNode) -> [SCNNode] {
        let wheelLeaves = leafMost(
            of: namedNodes(in: model) { name in
                name.contains("wheel") && !name.contains("well") && !name.contains("arch")
            }
        )
        let tireLeaves = leafMost(
            of: namedNodes(in: model) { name in
                name.contains("tire")
            }
        )

        var nodes = wheelLeaves
        for tire in tireLeaves {
            let alreadySpinning = nodes.contains { spinning in
                spinning === tire || tire.hasAncestor(spinning)
            }
            if !alreadySpinning {
                nodes.append(tire)
            }
        }
        return nodes
    }

    private static func namedNodes(
        in root: SCNNode,
        matching: (String) -> Bool
    ) -> [SCNNode] {
        var matches: [SCNNode] = []
        root.enumerateChildNodes { node, _ in
            guard let name = node.name?.lowercased(), matching(name) else { return }
            matches.append(node)
        }
        return matches
    }

    private static func rootMost(of nodes: [SCNNode]) -> [SCNNode] {
        nodes.filter { node in
            !nodes.contains { candidate in
                candidate !== node && node.hasAncestor(candidate)
            }
        }
    }

    private static func leafMost(of nodes: [SCNNode]) -> [SCNNode] {
        nodes.filter { node in
            !nodes.contains { candidate in
                candidate !== node && candidate.hasAncestor(node)
            }
        }
    }

    // MARK: - Load / normalize

    private static func loadCarModel() -> SCNNode? {
        let candidates = [
            Bundle.main.url(forResource: modelResourceName, withExtension: "usdz"),
            Bundle.main.url(forResource: modelResourceName, withExtension: "usdz", subdirectory: "Assets")
        ]

        guard let url = candidates.compactMap({ $0 }).first else {
            return nil
        }

        do {
            let modelScene = try SCNScene(url: url, options: [
                .convertUnitsToMeters: true
            ])

            let wrapper = SCNNode()
            //move (don't clone) so materials / textures stay intact
            for child in modelScene.rootNode.childNodes {
                child.removeFromParentNode()
                wrapper.addChildNode(child)
            }
            return wrapper.childNodes.isEmpty ? nil : wrapper
        } catch {
            return nil
        }
    }

    private static func normalize(_ model: SCNNode, into parent: SCNNode) {
        parent.addChildNode(model)

        let local = size(of: model.boundingBox)

        // Blender USD is Z-up (length on Y, height on Z). SceneKit is Y-up.
        var euler = SCNVector3Zero
        if local.y >= max(local.x, local.z) * 1.05 {
            euler.x = -.pi / 2
            model.eulerAngles = euler
        }

        var oriented = size(of: boundingBoxInParentSpace(of: model, parent: parent))
        if oriented.x > oriented.z * 1.15 {
            euler.y = .pi / 2
            model.eulerAngles = euler
            oriented = size(of: boundingBoxInParentSpace(of: model, parent: parent))
        }

        let longest = max(oriented.x, oriented.z)
        let targetLength: Float = 4.6
        let scale = longest > 0.001 ? targetLength / longest : 1
        model.scale = SCNVector3(scale, scale, scale)

        let bounds = boundingBoxInParentSpace(of: model, parent: parent)
        model.position = SCNVector3(
            model.position.x - (bounds.min.x + bounds.max.x) / 2,
            model.position.y - bounds.min.y,
            model.position.z - (bounds.min.z + bounds.max.z) / 2
        )
    }

    private static func restoreBodyPaint(on root: SCNNode) {
        let paintHints = ["body", "hood", "trunk", "door", "bumper", "fender", "paint", "roof"]
        let skipHints = ["glass", "window", "windshield", "light", "lens", "tire", "wheel", "chrome"]

        root.enumerateChildNodes { node, _ in
            let name = node.name?.lowercased() ?? ""
            if skipHints.contains(where: name.contains) { return }
            guard let materials = node.geometry?.materials else { return }

            let looksLikePaint = paintHints.contains(where: name.contains)

            for material in materials {
                if material.transparency < 0.98 { continue }

                let redDiffuse = isStronglyRed(material.diffuse.contents)
                let missingAlbedo = !hasImageContents(material.diffuse.contents)

                guard redDiffuse || (looksLikePaint && missingAlbedo) else { continue }

                material.lightingModel = .physicallyBased
                material.diffuse.contents = UIColor(white: 0.14, alpha: 1)
                material.metalness.contents = 0.72
                material.roughness.contents = 0.32
                material.emission.contents = UIColor.black
                material.multiply.contents = UIColor.white
            }
        }
    }

    private static func hasImageContents(_ contents: Any?) -> Bool {
        if contents is UIImage || contents is String { return true }
        guard let object = contents else { return false }
        return CFGetTypeID(object as CFTypeRef) == CGImage.typeID
    }

    private static func isStronglyRed(_ contents: Any?) -> Bool {
        if let color = contents as? UIColor {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return red > 0.45 && red > green + 0.18 && red > blue + 0.18
        }

        if let vector = contents as? SCNVector3 {
            return vector.x > 0.45 && vector.x > vector.y + 0.18 && vector.x > vector.z + 0.18
        }

        return false
    }

    private static func size(of bounds: (min: SCNVector3, max: SCNVector3)) -> SCNVector3 {
        SCNVector3(
            bounds.max.x - bounds.min.x,
            bounds.max.y - bounds.min.y,
            bounds.max.z - bounds.min.z
        )
    }

    // MARK: - Hotspots

    private static func addHotspots(to parent: SCNNode, around model: SCNNode) {
        let hotspots = SCNNode()
        hotspots.name = hotspotsNodeName
        parent.addChildNode(hotspots)

        let bounds = boundingBoxInParentSpace(of: model, parent: parent)
        let minB = bounds.min
        let maxB = bounds.max
        let width = maxB.x - minB.x
        let height = maxB.y - minB.y
        let length = maxB.z - minB.z
        let midX = (minB.x + maxB.x) / 2
        let midY = (minB.y + maxB.y) / 2
        let midZ = (minB.z + maxB.z) / 2
        let doorMidY = minB.y + height * 0.48
        let cabinZ = midZ + length * 0.02
        let cabinLength = length * 0.38
        let windowY = minB.y + height * 0.78
        let windowH = height * 0.28

        //front / drivetrain (hood + nose)
        hotspots.addChildNode(
            hotspot(
                area: .drivetrain,
                width: width * 0.85,
                height: height * 0.55,
                length: length * 0.28,
                position: SCNVector3(midX, midY * 0.85, maxB.z - length * 0.14)
            )
        )

        //upper body — mid-door and up (roof, pillars, upper panels)
        let bodyH = maxB.y - doorMidY
        hotspots.addChildNode(
            hotspot(
                area: .body,
                width: width * 0.9,
                height: bodyH,
                length: cabinLength,
                position: SCNVector3(midX, doorMidY + bodyH * 0.5, cabinZ)
            )
        )

        //windows — windshield, rear glass, and both side glass
        hotspots.addChildNode(
            hotspot(
                area: .interior,
                width: width * 0.72,
                height: windowH,
                length: length * 0.07,
                position: SCNVector3(midX, windowY, cabinZ + cabinLength * 0.42)
            )
        )
        hotspots.addChildNode(
            hotspot(
                area: .interior,
                width: width * 0.72,
                height: windowH,
                length: length * 0.07,
                position: SCNVector3(midX, windowY, cabinZ - cabinLength * 0.42)
            )
        )
        let sideWindowW = width * 0.08
        for x in [minB.x + sideWindowW * 0.45, maxB.x - sideWindowW * 0.45] {
            hotspots.addChildNode(
                hotspot(
                    area: .interior,
                    width: sideWindowW,
                    height: windowH,
                    length: cabinLength * 0.85,
                    position: SCNVector3(x, windowY, cabinZ)
                )
            )
        }

        //rear / misc (trunk)
        hotspots.addChildNode(
            hotspot(
                area: .misc,
                width: width * 0.85,
                height: height * 0.5,
                length: length * 0.24,
                position: SCNVector3(midX, midY * 0.85, minB.z + length * 0.12)
            )
        )

        //chassis — lower body from mid-door down, including the underside
        hotspots.addChildNode(
            hotspot(
                area: .chassis,
                width: width * 0.9,
                height: doorMidY - minB.y + height * 0.04,
                length: length * 0.58,
                position: SCNVector3(midX, (minB.y + doorMidY) * 0.5, midZ)
            )
        )

        //wheels — four lower corner volumes
        let wheelH = height * 0.38
        let wheelL = length * 0.18
        let wheelW = width * 0.22
        let wheelY = minB.y + wheelH * 0.55
        let frontZ = maxB.z - length * 0.22
        let rearZ = minB.z + length * 0.22
        let leftX = minB.x + width * 0.08
        let rightX = maxB.x - width * 0.08

        for (x, z) in [(leftX, frontZ), (rightX, frontZ), (leftX, rearZ), (rightX, rearZ)] {
            hotspots.addChildNode(
                hotspot(
                    area: .wheels,
                    width: wheelW,
                    height: wheelH,
                    length: wheelL,
                    position: SCNVector3(x, wheelY, z)
                )
            )
        }
    }

    private static func hotspot(
        area: VehicleArea,
        width: Float,
        height: Float,
        length: Float,
        position: SCNVector3
    ) -> SCNNode {
        let box = SCNBox(
            width: CGFloat(width),
            height: CGFloat(height),
            length: CGFloat(length),
            chamferRadius: 0
        )
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.transparency = 1
        material.writesToDepthBuffer = false
        material.readsFromDepthBuffer = false
        box.materials = [material]

        let node = SCNNode(geometry: box)
        node.name = area.rawValue
        node.position = position
        node.opacity = 0.01 //nearly invisible but still hittable
        node.renderingOrder = 100
        return node
    }

    private static func boundingBoxInParentSpace(
        of node: SCNNode,
        parent: SCNNode
    ) -> (min: SCNVector3, max: SCNVector3) {
        let (localMin, localMax) = node.boundingBox
        let corners = [
            SCNVector3(localMin.x, localMin.y, localMin.z),
            SCNVector3(localMin.x, localMin.y, localMax.z),
            SCNVector3(localMin.x, localMax.y, localMin.z),
            SCNVector3(localMin.x, localMax.y, localMax.z),
            SCNVector3(localMax.x, localMin.y, localMin.z),
            SCNVector3(localMax.x, localMin.y, localMax.z),
            SCNVector3(localMax.x, localMax.y, localMin.z),
            SCNVector3(localMax.x, localMax.y, localMax.z)
        ]

        var minOut = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxOut = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)

        for corner in corners {
            let world = node.convertPosition(corner, to: parent)
            minOut.x = min(minOut.x, world.x)
            minOut.y = min(minOut.y, world.y)
            minOut.z = min(minOut.z, world.z)
            maxOut.x = max(maxOut.x, world.x)
            maxOut.y = max(maxOut.y, world.y)
            maxOut.z = max(maxOut.z, world.z)
        }

        return (minOut, maxOut)
    }

    // MARK: - Lighting

    private static func addLighting(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 500
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 900
        key.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 350
        fill.eulerAngles = SCNVector3(-0.2, -1.0, 0)
        scene.rootNode.addChildNode(fill)
    }
}

private extension SCNNode {
    func hasAncestor(_ ancestor: SCNNode) -> Bool {
        var current = parent
        while let node = current {
            if node === ancestor { return true }
            current = node.parent
        }
        return false
    }
}
