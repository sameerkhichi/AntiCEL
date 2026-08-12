import SceneKit
import UIKit

/// Blank-slate sport sedan silhouette (S4-inspired proportions, no branding).
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"
    static let cameraNodeName = "mainCamera"

    static let defaultCameraPosition = SCNVector3(3.6, 1.8, 4.2)
    static let defaultCameraTarget = SCNVector3(0, 0.45, 0)

    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let sedan = makeSedan()
        sedan.name = sedanNodeName
        scene.rootNode.addChildNode(sedan)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1250
        key.light?.castsShadow = false
        key.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 340
        fill.eulerAngles = SCNVector3(-0.2, -1.0, 0)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 280
        rim.eulerAngles = SCNVector3(0.15, 2.5, 0)
        scene.rootNode.addChildNode(rim)

        return scene
    }

    private static func makeSedan() -> SCNNode {
        let root = SCNNode()

        let paint = mat(UIColor(white: 0.07, alpha: 1), metalness: 0.72, roughness: 0.3)
        let dark = mat(UIColor(white: 0.03, alpha: 1), metalness: 0.5, roughness: 0.45)
        let glass = mat(
            UIColor(red: 0.22, green: 0.28, blue: 0.34, alpha: 1),
            metalness: 0.15,
            roughness: 0.08
        )
        glass.transparency = 0.5
        let rubber = mat(UIColor(white: 0.04, alpha: 1), metalness: 0.05, roughness: 0.92)
        let chrome = chromeMat()

        let body = extrudedProfile(
            path: sedanSideProfile(),
            depth: 1.84,
            material: paint,
            area: .body
        )
        root.addChildNode(body)

        let greenhouse = extrudedProfile(
            path: greenhouseProfile(),
            depth: 1.68,
            material: glass,
            area: .body
        )
        greenhouse.position.y = 0.01
        root.addChildNode(greenhouse)

        let hoodPivot = SCNNode()
        hoodPivot.name = "hoodPivot"
        hoodPivot.position = SCNVector3(0, 0.66, 0.55)
        root.addChildNode(hoodPivot)

        let hood = roundedBox(width: 1.76, height: 0.045, length: 1.35, chamfer: 0.04, material: paint)
        hood.position = SCNVector3(0, 0.015, 0.68)
        hood.name = VehicleArea.drivetrain.rawValue
        hoodPivot.addChildNode(hood)

        let engine = roundedBox(width: 0.68, height: 0.3, length: 0.68, chamfer: 0.04, material: dark)
        engine.position = SCNVector3(0, 0.4, 1.2)
        engine.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(engine)

        let frontLip = roundedBox(width: 1.68, height: 0.09, length: 0.2, chamfer: 0.035, material: dark)
        frontLip.position = SCNVector3(0, 0.14, 2.28)
        frontLip.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(frontLip)

        addHeadlight(to: root, x: -0.62)
        addHeadlight(to: root, x: 0.62)

        let trunkPivot = SCNNode()
        trunkPivot.name = "trunkPivot"
        trunkPivot.position = SCNVector3(0, 0.70, -1.15)
        root.addChildNode(trunkPivot)

        let trunk = roundedBox(width: 1.7, height: 0.045, length: 0.82, chamfer: 0.04, material: paint)
        trunk.position = SCNVector3(0, 0.015, -0.38)
        trunk.name = VehicleArea.misc.rawValue
        trunkPivot.addChildNode(trunk)

        let rearLip = roundedBox(width: 1.68, height: 0.09, length: 0.18, chamfer: 0.035, material: dark)
        rearLip.position = SCNVector3(0, 0.14, -2.28)
        rearLip.name = VehicleArea.misc.rawValue
        root.addChildNode(rearLip)

        addTaillight(to: root, x: -0.72)
        addTaillight(to: root, x: 0.72)

        addMirror(to: root, x: -0.95)
        addMirror(to: root, x: 0.95)

        //larger wheels seated in larger arches
        addWheel(to: root, x: -1.02, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 1.02, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: -1.02, z: -1.35, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 1.02, z: -1.35, rubber: rubber, chrome: chrome)

        return root
    }

    // MARK: - Profiles

    private static func sedanSideProfile() -> UIBezierPath {
        let path = UIBezierPath()

        //smoother, rounder roofline (less boxy cabin)
        path.move(to: CGPoint(x: 2.30, y: 0.10))
        path.addLine(to: CGPoint(x: 2.40, y: 0.24))
        path.addQuadCurve(
            to: CGPoint(x: 2.16, y: 0.48),
            controlPoint: CGPoint(x: 2.44, y: 0.40)
        )
        //hood
        path.addQuadCurve(
            to: CGPoint(x: 0.72, y: 0.66),
            controlPoint: CGPoint(x: 1.50, y: 0.72)
        )
        //windshield into a rounded roof dome
        path.addCurve(
            to: CGPoint(x: -1.08, y: 1.12),
            controlPoint1: CGPoint(x: 0.45, y: 1.08),
            controlPoint2: CGPoint(x: -0.25, y: 1.28)
        )
        //rounded rear roof → rear glass
        path.addCurve(
            to: CGPoint(x: -1.62, y: 0.80),
            controlPoint1: CGPoint(x: -1.35, y: 1.10),
            controlPoint2: CGPoint(x: -1.50, y: 0.95)
        )
        path.addQuadCurve(
            to: CGPoint(x: -2.12, y: 0.72),
            controlPoint: CGPoint(x: -1.88, y: 0.74)
        )
        path.addQuadCurve(
            to: CGPoint(x: -2.34, y: 0.36),
            controlPoint: CGPoint(x: -2.40, y: 0.62)
        )
        path.addLine(to: CGPoint(x: -2.28, y: 0.10))

        //large circular wheel wells (radius > tire)
        addWheelWell(to: path, centerX: -1.35, groundY: 0.10, radius: 0.55)
        path.addLine(to: CGPoint(x: 0.78, y: 0.10))
        addWheelWell(to: path, centerX: 1.32, groundY: 0.10, radius: 0.55)
        path.addLine(to: CGPoint(x: 2.30, y: 0.10))
        path.close()
        return path
    }

    /// Cuts an upward semicircle into the rocker (travelling rear→front along the bottom).
    private static func addWheelWell(
        to path: UIBezierPath,
        centerX: CGFloat,
        groundY: CGFloat,
        radius: CGFloat
    ) {
        path.addLine(to: CGPoint(x: centerX - radius, y: groundY))
        path.addArc(
            withCenter: CGPoint(x: centerX, y: groundY),
            radius: radius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: false
        )
    }

    private static func greenhouseProfile() -> UIBezierPath {
        let path = UIBezierPath()
        //follows the softer roof dome
        path.move(to: CGPoint(x: 0.62, y: 0.70))
        path.addCurve(
            to: CGPoint(x: -1.05, y: 1.06),
            controlPoint1: CGPoint(x: 0.35, y: 1.02),
            controlPoint2: CGPoint(x: -0.30, y: 1.20)
        )
        path.addCurve(
            to: CGPoint(x: -1.48, y: 0.78),
            controlPoint1: CGPoint(x: -1.28, y: 1.02),
            controlPoint2: CGPoint(x: -1.42, y: 0.90)
        )
        path.addLine(to: CGPoint(x: -1.40, y: 0.70))
        path.close()
        return path
    }

    private static func extrudedProfile(
        path: UIBezierPath,
        depth: CGFloat,
        material: SCNMaterial,
        area: VehicleArea
    ) -> SCNNode {
        let shape = SCNShape(path: path, extrusionDepth: depth)
        shape.chamferMode = .both
        shape.chamferRadius = 0.045
        shape.firstMaterial = material.copy() as? SCNMaterial ?? material
        shape.firstMaterial?.isDoubleSided = false

        let node = SCNNode(geometry: shape)
        node.eulerAngles.y = -.pi / 2
        node.name = area.rawValue
        return node
    }

    // MARK: - Details

    private static func addHeadlight(to parent: SCNNode, x: Float) {
        //thicker horizontal unit — vaguely modern sedan, not a badge clone
        let housing = roundedBox(
            width: 0.48,
            height: 0.15,
            length: 0.09,
            chamfer: 0.045,
            material: {
                let m = mat(UIColor(white: 0.92, alpha: 1), metalness: 0.15, roughness: 0.12)
                m.emission.contents = UIColor(white: 0.55, alpha: 1)
                return m
            }()
        )
        housing.position = SCNVector3(x, 0.46, 2.16)
        housing.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(housing)

        let lens = roundedBox(
            width: 0.38,
            height: 0.09,
            length: 0.04,
            chamfer: 0.03,
            material: {
                let m = mat(UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1), metalness: 0.05, roughness: 0.06)
                m.emission.contents = UIColor(red: 1, green: 0.97, blue: 0.9, alpha: 1)
                return m
            }()
        )
        lens.position = SCNVector3(x, 0.46, 2.22)
        lens.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(lens)
    }

    private static func addTaillight(to parent: SCNNode, x: Float) {
        let light = roundedBox(width: 0.38, height: 0.1, length: 0.07, chamfer: 0.03, material: {
            let m = mat(UIColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1), metalness: 0.2, roughness: 0.3)
            m.emission.contents = UIColor(red: 1.0, green: 0.08, blue: 0.08, alpha: 1)
            return m
        }())
        light.position = SCNVector3(x, 0.52, -2.22)
        light.name = VehicleArea.misc.rawValue
        parent.addChildNode(light)
    }

    private static func addMirror(to parent: SCNNode, x: Float) {
        let arm = roundedBox(
            width: 0.08,
            height: 0.05,
            length: 0.14,
            chamfer: 0.02,
            material: mat(UIColor(white: 0.1, alpha: 1), metalness: 0.55, roughness: 0.35)
        )
        arm.position = SCNVector3(x, 0.74, 0.55)
        arm.name = VehicleArea.body.rawValue
        parent.addChildNode(arm)
    }

    private static func addWheel(
        to parent: SCNNode,
        x: Float,
        z: Float,
        rubber: SCNMaterial,
        chrome: SCNMaterial
    ) {
        let tireRadius: Float = 0.42
        let pivot = SCNNode()
        pivot.name = VehicleArea.wheels.rawValue
        pivot.position = SCNVector3(x, tireRadius, z)
        parent.addChildNode(pivot)

        let tire = SCNTube(innerRadius: 0.26, outerRadius: CGFloat(tireRadius), height: 0.30)
        tire.firstMaterial = rubber.copy() as? SCNMaterial ?? rubber
        let tireNode = SCNNode(geometry: tire)
        tireNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tireNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(tireNode)

        let disc = SCNCylinder(radius: 0.28, height: 0.08)
        disc.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let discNode = SCNNode(geometry: disc)
        discNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        discNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(discNode)

        for i in 0..<7 {
            let spoke = SCNBox(width: 0.06, height: 0.50, length: 0.05, chamferRadius: 0.01)
            spoke.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
            let spokeNode = SCNNode(geometry: spoke)
            spokeNode.eulerAngles = SCNVector3(Float(i) * (.pi * 2 / 7), 0, 0)
            spokeNode.name = VehicleArea.wheels.rawValue
            pivot.addChildNode(spokeNode)
        }

        let ring = SCNTube(innerRadius: 0.26, outerRadius: 0.29, height: 0.1)
        ring.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let ringNode = SCNNode(geometry: ring)
        ringNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        ringNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(ringNode)

        let cap = SCNSphere(radius: 0.075)
        cap.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let capNode = SCNNode(geometry: cap)
        capNode.scale = SCNVector3(0.75, 0.75, 0.4)
        capNode.position = SCNVector3(x > 0 ? 0.07 : -0.07, 0, 0)
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
            chamferRadius: min(chamfer, min(width, height, length) * 0.4)
        )
        geometry.chamferSegmentCount = 12
        geometry.firstMaterial = material.copy() as? SCNMaterial ?? material
        return SCNNode(geometry: geometry)
    }

    private static func chromeMat() -> SCNMaterial {
        //mid-gray base + high metalness reads as chrome (pure white looks chalky)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 0.45, alpha: 1)
        material.metalness.contents = 1.0
        material.roughness.contents = 0.08
        material.lightingModel = .physicallyBased
        return material
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
