import SceneKit
import UIKit

/// Loads the bundled generic sedan USDZ and attaches invisible tap zones.
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"
    static let cameraNodeName = "mainCamera"
    static let modelNodeName = "carModel"
    static let hotspotsNodeName = "hotspots"

    static let defaultCameraPosition = SCNVector3(3.8, 2.0, 4.6)
    static let defaultCameraTarget = SCNVector3(0, 0.6, 0)
    static let overheadCameraPosition = SCNVector3(0, 7.2, 0.12)
    static let overheadCameraTarget = SCNVector3(0, 0.6, 0)

    static let hoodOpenRadians: Float = 45 * .pi / 180
    static let trunkOpenRadians: Float = 60 * .pi / 180
    static let wheelSpinActionKey = "wheelSpin"

    private static let modelResourceName = "Generic_Sedan_Car"

    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let sedan = SCNNode()
        sedan.name = sedanNodeName

        if let model = loadCarModel() {
            model.name = modelNodeName
            normalize(model, into: sedan)
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
        let wheels = namedNodes(in: model) { name in
            name.contains("wheel") && !name.contains("well") && !name.contains("arch")
        }
        let leaves = leafMost(of: wheels)
        if !leaves.isEmpty { return leaves }

        return leafMost(
            of: namedNodes(in: model) { name in
                name.contains("tire")
            }
        )
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
                .checkConsistency: true,
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

        let (minVec, maxVec) = model.boundingBox
        let size = SCNVector3(
            maxVec.x - minVec.x,
            maxVec.y - minVec.y,
            maxVec.z - minVec.z
        )

        let longest = max(size.x, size.z)
        let targetLength: Float = 4.6
        let scale = longest > 0.001 ? targetLength / longest : 1
        model.scale = SCNVector3(scale, scale, scale)

        //point the long axis down +Z when the asset is authored along X
        if size.x > size.z * 1.15 {
            model.eulerAngles.y = .pi / 2
        }

        //center on origin and plant on the ground using parent-space bounds
        let bounds = boundingBoxInParentSpace(of: model, parent: parent)
        model.position = SCNVector3(
            model.position.x - (bounds.min.x + bounds.max.x) / 2,
            model.position.y - bounds.min.y,
            model.position.z - (bounds.min.z + bounds.max.z) / 2
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

        //cabin / body
        hotspots.addChildNode(
            hotspot(
                area: .body,
                width: width * 0.9,
                height: height * 0.7,
                length: length * 0.36,
                position: SCNVector3(midX, midY * 1.05, (minB.z + maxB.z) / 2 + length * 0.02)
            )
        )

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
