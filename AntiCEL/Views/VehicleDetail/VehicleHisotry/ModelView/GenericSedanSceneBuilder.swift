import SceneKit
import UIKit

/// Builds a blank-slate generic sedan from primitives (no brand cues).
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"

    static func makeScene(backgroundColor: UIColor) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = backgroundColor

        let sedan = makeSedan()
        sedan.name = sedanNodeName
        scene.rootNode.addChildNode(sedan)

        //soft contact shadow only — no visible "stage"
        let ground = SCNPlane(width: 5.5, height: 3.2)
        ground.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.14)
        ground.firstMaterial?.transparent.contents = UIColor.black.withAlphaComponent(0.14)
        ground.firstMaterial?.lightingModel = .constant
        ground.firstMaterial?.writesToDepthBuffer = false
        let groundNode = SCNNode(geometry: ground)
        groundNode.eulerAngles.x = -.pi / 2
        groundNode.position = SCNVector3(0, 0.001, 0)
        groundNode.opacity = 0.55
        scene.rootNode.addChildNode(groundNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 420
        fill.eulerAngles = SCNVector3(-0.25, -0.9, 0)
        scene.rootNode.addChildNode(fill)

        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.intensity = 280
        rimLight.eulerAngles = SCNVector3(0.2, 2.4, 0)
        scene.rootNode.addChildNode(rimLight)

        return scene
    }

    private static func makeSedan() -> SCNNode {
        let root = SCNNode()

        let paint = mat(UIColor(white: 0.78, alpha: 1), metalness: 0.55, roughness: 0.32)
        let darkTrim = mat(UIColor(white: 0.18, alpha: 1), metalness: 0.4, roughness: 0.45)
        let glass = mat(UIColor(red: 0.55, green: 0.72, blue: 0.82, alpha: 0.42), metalness: 0.05, roughness: 0.05)
        glass.transparency = 0.45
        let rubber = mat(UIColor(white: 0.08, alpha: 1), metalness: 0.05, roughness: 0.9)
        let chrome = mat(UIColor(white: 0.85, alpha: 1), metalness: 0.95, roughness: 0.18)

        // ——— lower body / rocker ———
        let rocker = roundedBox(width: 1.92, height: 0.34, length: 4.35, chamfer: 0.12, material: paint)
        rocker.position = SCNVector3(0, 0.30, 0)
        rocker.name = VehicleArea.body.rawValue
        root.addChildNode(rocker)

        // ——— cabin ———
        let cabin = roundedBox(width: 1.78, height: 0.52, length: 2.05, chamfer: 0.14, material: paint)
        cabin.position = SCNVector3(0, 0.72, -0.08)
        cabin.name = VehicleArea.body.rawValue
        root.addChildNode(cabin)

        // ——— roof (slightly inset) ———
        let roof = roundedBox(width: 1.52, height: 0.14, length: 1.55, chamfer: 0.08, material: paint)
        roof.position = SCNVector3(0, 1.04, -0.12)
        roof.name = VehicleArea.body.rawValue
        root.addChildNode(roof)

        // ——— glass ———
        let windshield = roundedBox(width: 1.48, height: 0.38, length: 0.08, chamfer: 0.03, material: glass)
        windshield.position = SCNVector3(0, 0.86, 0.88)
        windshield.eulerAngles = SCNVector3(-0.55, 0, 0)
        windshield.name = VehicleArea.body.rawValue
        root.addChildNode(windshield)

        let rearGlass = roundedBox(width: 1.42, height: 0.32, length: 0.08, chamfer: 0.03, material: glass)
        rearGlass.position = SCNVector3(0, 0.86, -1.05)
        rearGlass.eulerAngles = SCNVector3(0.5, 0, 0)
        rearGlass.name = VehicleArea.body.rawValue
        root.addChildNode(rearGlass)

        let sideGlassL = roundedBox(width: 0.05, height: 0.30, length: 1.65, chamfer: 0.02, material: glass)
        sideGlassL.position = SCNVector3(-0.90, 0.82, -0.08)
        sideGlassL.name = VehicleArea.body.rawValue
        root.addChildNode(sideGlassL)

        let sideGlassR = roundedBox(width: 0.05, height: 0.30, length: 1.65, chamfer: 0.02, material: glass)
        sideGlassR.position = SCNVector3(0.90, 0.82, -0.08)
        sideGlassR.name = VehicleArea.body.rawValue
        root.addChildNode(sideGlassR)

        // ——— hood / drivetrain ———
        let hoodPivot = SCNNode()
        hoodPivot.name = "hoodPivot"
        hoodPivot.position = SCNVector3(0, 0.52, 0.48)
        root.addChildNode(hoodPivot)

        let hood = roundedBox(width: 1.78, height: 0.11, length: 1.25, chamfer: 0.08, material: paint)
        hood.position = SCNVector3(0, 0.02, 0.62)
        hood.name = VehicleArea.drivetrain.rawValue
        hoodPivot.addChildNode(hood)

        let engine = roundedBox(width: 0.72, height: 0.36, length: 0.72, chamfer: 0.04, material: darkTrim)
        engine.position = SCNVector3(0, 0.42, 1.15)
        engine.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(engine)

        // front bumper
        let frontBumper = roundedBox(width: 1.88, height: 0.22, length: 0.28, chamfer: 0.08, material: darkTrim)
        frontBumper.position = SCNVector3(0, 0.26, 2.12)
        frontBumper.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(frontBumper)

        // ——— headlights (generic clear lenses) ———
        addHeadlight(to: root, x: -0.62)
        addHeadlight(to: root, x: 0.62)

        // ——— trunk / misc ———
        let trunkPivot = SCNNode()
        trunkPivot.name = "trunkPivot"
        trunkPivot.position = SCNVector3(0, 0.52, -1.02)
        root.addChildNode(trunkPivot)

        let trunk = roundedBox(width: 1.78, height: 0.12, length: 1.0, chamfer: 0.08, material: paint)
        trunk.position = SCNVector3(0, 0.02, -0.48)
        trunk.name = VehicleArea.misc.rawValue
        trunkPivot.addChildNode(trunk)

        let rearBumper = roundedBox(width: 1.88, height: 0.22, length: 0.28, chamfer: 0.08, material: darkTrim)
        rearBumper.position = SCNVector3(0, 0.26, -2.12)
        rearBumper.name = VehicleArea.misc.rawValue
        root.addChildNode(rearBumper)

        // ——— taillights ———
        addTaillight(to: root, x: -0.62)
        addTaillight(to: root, x: 0.62)

        // ——— wheels with visible multi-spoke rims ———
        addWheel(to: root, x: -0.92, z: 1.28, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.92, z: 1.28, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: -0.92, z: -1.28, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.92, z: -1.28, rubber: rubber, chrome: chrome)

        return root
    }

    private static func addHeadlight(to parent: SCNNode, x: Float) {
        let housing = SCNSphere(radius: 0.11)
        housing.segmentCount = 24
        let housingMat = mat(UIColor(white: 0.92, alpha: 1), metalness: 0.2, roughness: 0.15)
        housingMat.emission.contents = UIColor(white: 0.55, alpha: 1)
        housing.firstMaterial = housingMat

        let node = SCNNode(geometry: housing)
        node.scale = SCNVector3(1.35, 0.7, 0.55)
        node.position = SCNVector3(x, 0.42, 2.05)
        node.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(node)

        //inner lens glow
        let lens = SCNSphere(radius: 0.06)
        let lensMat = mat(UIColor(red: 1, green: 0.97, blue: 0.85, alpha: 1), metalness: 0.05, roughness: 0.1)
        lensMat.emission.contents = UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 1)
        lens.firstMaterial = lensMat
        let lensNode = SCNNode(geometry: lens)
        lensNode.position = SCNVector3(x, 0.42, 2.12)
        lensNode.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(lensNode)
    }

    private static func addTaillight(to parent: SCNNode, x: Float) {
        let light = roundedBox(width: 0.32, height: 0.12, length: 0.08, chamfer: 0.03, material: {
            let m = mat(UIColor(red: 0.75, green: 0.08, blue: 0.08, alpha: 1), metalness: 0.15, roughness: 0.35)
            m.emission.contents = UIColor(red: 0.85, green: 0.05, blue: 0.05, alpha: 1)
            return m
        }())
        light.position = SCNVector3(x, 0.48, -2.12)
        light.name = VehicleArea.misc.rawValue
        parent.addChildNode(light)
    }

    private static func addWheel(
        to parent: SCNNode,
        x: Float,
        z: Float,
        rubber: SCNMaterial,
        chrome: SCNMaterial
    ) {
        //pivot stays axis-aligned so spin around X = horizontal axle
        let pivot = SCNNode()
        pivot.name = VehicleArea.wheels.rawValue
        pivot.position = SCNVector3(x, 0.33, z)
        parent.addChildNode(pivot)

        let tire = SCNTube(innerRadius: 0.20, outerRadius: 0.34, height: 0.24)
        tire.firstMaterial = rubber.copy() as? SCNMaterial ?? rubber
        let tireNode = SCNNode(geometry: tire)
        tireNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tireNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(tireNode)

        //rim disc
        let disc = SCNCylinder(radius: 0.20, height: 0.08)
        disc.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let discNode = SCNNode(geometry: disc)
        discNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        discNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(discNode)

        //5 spokes in the wheel plane — readable motion when spinning around X
        for i in 0..<5 {
            let spoke = SCNBox(width: 0.05, height: 0.36, length: 0.045, chamferRadius: 0.008)
            spoke.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
            let spokeNode = SCNNode(geometry: spoke)
            spokeNode.eulerAngles = SCNVector3(Float(i) * (.pi * 2 / 5), 0, 0)
            spokeNode.name = VehicleArea.wheels.rawValue
            pivot.addChildNode(spokeNode)
        }

        //center cap
        let cap = SCNSphere(radius: 0.06)
        cap.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let capNode = SCNNode(geometry: cap)
        capNode.scale = SCNVector3(0.7, 0.7, 0.45)
        //nudge slightly outward so cap reads from the side
        capNode.position = SCNVector3(x > 0 ? 0.06 : -0.06, 0, 0)
        capNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(capNode)
    }

    private static func roundedBox(
        width: CGFloat,
        height: CGFloat,
        length: CGFloat,
        chamfer: CGFloat,
        material: SCNMaterial
    ) -> SCNNode {
        let geometry = SCNBox(
            width: width,
            height: height,
            length: length,
            chamferRadius: min(chamfer, min(width, height, length) * 0.45)
        )
        geometry.chamferSegmentCount = 12
        geometry.widthSegmentCount = 1
        geometry.heightSegmentCount = 1
        geometry.lengthSegmentCount = 1
        geometry.firstMaterial = material.copy() as? SCNMaterial ?? material
        return SCNNode(geometry: geometry)
    }

    private static func mat(
        _ color: UIColor,
        metalness: CGFloat = 0.25,
        roughness: CGFloat = 0.55
    ) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.metalness.contents = metalness
        material.roughness.contents = roughness
        material.lightingModel = .physicallyBased
        return material
    }
}
