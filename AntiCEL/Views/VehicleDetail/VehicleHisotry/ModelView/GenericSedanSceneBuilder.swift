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

        let shadow = SCNPlane(width: 5.2, height: 2.6)
        let shadowMat = SCNMaterial()
        shadowMat.diffuse.contents = UIColor.black
        shadowMat.transparency = 0.82
        shadowMat.lightingModel = .constant
        shadowMat.writesToDepthBuffer = false
        shadow.firstMaterial = shadowMat
        let shadowNode = SCNNode(geometry: shadow)
        shadowNode.eulerAngles.x = -.pi / 2
        shadowNode.position = SCNVector3(0, 0.002, 0)
        shadowNode.opacity = 0.2
        scene.rootNode.addChildNode(shadowNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1300
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 320
        fill.eulerAngles = SCNVector3(-0.2, -1.0, 0)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 300
        rim.eulerAngles = SCNVector3(0.15, 2.5, 0)
        scene.rootNode.addChildNode(rim)

        return scene
    }

    private static func makeSedan() -> SCNNode {
        let root = SCNNode()

        //black paint so headlights / taillights read clearly
        let paint = mat(UIColor(white: 0.07, alpha: 1), metalness: 0.7, roughness: 0.32)
        let dark = mat(UIColor(white: 0.03, alpha: 1), metalness: 0.5, roughness: 0.45)
        let glass = mat(
            UIColor(red: 0.25, green: 0.32, blue: 0.38, alpha: 1),
            metalness: 0.15,
            roughness: 0.08
        )
        glass.transparency = 0.5
        let rubber = mat(UIColor(white: 0.05, alpha: 1), metalness: 0.05, roughness: 0.92)
        let chrome = mat(UIColor(white: 0.9, alpha: 1), metalness: 0.96, roughness: 0.14)

        let body = extrudedProfile(
            path: sedanSideProfile(),
            depth: 1.84,
            material: paint,
            area: .body
        )
        root.addChildNode(body)

        let shoulder = extrudedProfile(
            path: shoulderProfile(),
            depth: 1.90,
            material: paint,
            area: .body
        )
        shoulder.position.y = 0.015
        root.addChildNode(shoulder)

        let greenhouse = extrudedProfile(
            path: greenhouseProfile(),
            depth: 1.70,
            material: glass,
            area: .body
        )
        greenhouse.position.y = 0.01
        root.addChildNode(greenhouse)

        //hood at +Z (front)
        let hoodPivot = SCNNode()
        hoodPivot.name = "hoodPivot"
        hoodPivot.position = SCNVector3(0, 0.68, 0.55)
        root.addChildNode(hoodPivot)

        let hood = roundedBox(width: 1.76, height: 0.045, length: 1.35, chamfer: 0.035, material: paint)
        hood.position = SCNVector3(0, 0.015, 0.68)
        hood.name = VehicleArea.drivetrain.rawValue
        hoodPivot.addChildNode(hood)

        let engine = roundedBox(width: 0.68, height: 0.3, length: 0.68, chamfer: 0.04, material: dark)
        engine.position = SCNVector3(0, 0.4, 1.2)
        engine.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(engine)

        let frontLip = roundedBox(width: 1.68, height: 0.09, length: 0.2, chamfer: 0.035, material: dark)
        frontLip.position = SCNVector3(0, 0.15, 2.28)
        frontLip.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(frontLip)

        addHeadlight(to: root, x: -0.68)
        addHeadlight(to: root, x: 0.68)

        //trunk at -Z (rear)
        let trunkPivot = SCNNode()
        trunkPivot.name = "trunkPivot"
        trunkPivot.position = SCNVector3(0, 0.72, -1.15)
        root.addChildNode(trunkPivot)

        let trunk = roundedBox(width: 1.7, height: 0.045, length: 0.82, chamfer: 0.035, material: paint)
        trunk.position = SCNVector3(0, 0.015, -0.38)
        trunk.name = VehicleArea.misc.rawValue
        trunkPivot.addChildNode(trunk)

        let rearLip = roundedBox(width: 1.68, height: 0.09, length: 0.18, chamfer: 0.035, material: dark)
        rearLip.position = SCNVector3(0, 0.15, -2.28)
        rearLip.name = VehicleArea.misc.rawValue
        root.addChildNode(rearLip)

        addTaillight(to: root, x: -0.72)
        addTaillight(to: root, x: 0.72)

        addMirror(to: root, x: -0.95)
        addMirror(to: root, x: 0.95)

        //wheel centers aligned with deeper wells
        addWheel(to: root, x: -0.98, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.98, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: -0.98, z: -1.35, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.98, z: -1.35, rubber: rubber, chrome: chrome)

        return root
    }

    // MARK: - Profiles

    private static func sedanSideProfile() -> UIBezierPath {
        let path = UIBezierPath()

        //front (+x) → rear (-x)
        path.move(to: CGPoint(x: 2.30, y: 0.12))
        path.addLine(to: CGPoint(x: 2.38, y: 0.26))
        path.addQuadCurve(
            to: CGPoint(x: 2.18, y: 0.50),
            controlPoint: CGPoint(x: 2.42, y: 0.42)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0.78, y: 0.68),
            controlPoint: CGPoint(x: 1.55, y: 0.74)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0.22, y: 1.14),
            controlPoint: CGPoint(x: 0.55, y: 1.00)
        )
        path.addQuadCurve(
            to: CGPoint(x: -1.05, y: 1.18),
            controlPoint: CGPoint(x: -0.40, y: 1.24)
        )
        path.addQuadCurve(
            to: CGPoint(x: -1.55, y: 0.84),
            controlPoint: CGPoint(x: -1.35, y: 1.06)
        )
        path.addLine(to: CGPoint(x: -2.10, y: 0.76))
        path.addQuadCurve(
            to: CGPoint(x: -2.34, y: 0.40),
            controlPoint: CGPoint(x: -2.38, y: 0.66)
        )
        path.addLine(to: CGPoint(x: -2.28, y: 0.12))

        //deeper wheel wells so tires sit in the arches (not through the rocker)
        path.addLine(to: CGPoint(x: -1.78, y: 0.12))
        path.addQuadCurve(
            to: CGPoint(x: -0.92, y: 0.12),
            controlPoint: CGPoint(x: -1.35, y: 0.78)
        )
        path.addLine(to: CGPoint(x: 0.88, y: 0.12))
        path.addQuadCurve(
            to: CGPoint(x: 1.76, y: 0.12),
            controlPoint: CGPoint(x: 1.32, y: 0.78)
        )
        path.addLine(to: CGPoint(x: 2.30, y: 0.12))
        path.close()
        return path
    }

    private static func shoulderProfile() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.05, y: 0.46))
        path.addLine(to: CGPoint(x: 0.85, y: 0.60))
        path.addLine(to: CGPoint(x: 0.35, y: 0.60))
        path.addLine(to: CGPoint(x: -1.50, y: 0.64))
        path.addLine(to: CGPoint(x: -2.05, y: 0.60))
        path.addLine(to: CGPoint(x: -2.05, y: 0.50))
        path.addLine(to: CGPoint(x: 2.05, y: 0.38))
        path.close()
        return path
    }

    private static func greenhouseProfile() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.70, y: 0.72))
        path.addLine(to: CGPoint(x: 0.20, y: 1.10))
        path.addQuadCurve(
            to: CGPoint(x: -1.00, y: 1.12),
            controlPoint: CGPoint(x: -0.40, y: 1.18)
        )
        path.addLine(to: CGPoint(x: -1.42, y: 0.86))
        path.addLine(to: CGPoint(x: -1.35, y: 0.72))
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
        shape.chamferRadius = 0.02
        shape.firstMaterial = material.copy() as? SCNMaterial ?? material
        shape.firstMaterial?.isDoubleSided = false

        let node = SCNNode(geometry: shape)
        //path +X (nose) → scene +Z after this rotation
        node.eulerAngles.y = -.pi / 2
        node.name = area.rawValue
        return node
    }

    // MARK: - Details

    private static func addHeadlight(to parent: SCNNode, x: Float) {
        let housing = SCNSphere(radius: 0.10)
        housing.segmentCount = 28
        let housingMat = mat(UIColor(white: 0.95, alpha: 1), metalness: 0.12, roughness: 0.1)
        housingMat.emission.contents = UIColor(white: 0.65, alpha: 1)
        housing.firstMaterial = housingMat

        let node = SCNNode(geometry: housing)
        node.scale = SCNVector3(1.55, 0.55, 0.45)
        node.position = SCNVector3(x, 0.46, 2.18)
        node.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(node)

        let lens = SCNSphere(radius: 0.05)
        let lensMat = mat(UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1), metalness: 0.05, roughness: 0.06)
        lensMat.emission.contents = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
        lens.firstMaterial = lensMat
        let lensNode = SCNNode(geometry: lens)
        lensNode.position = SCNVector3(x, 0.46, 2.25)
        lensNode.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(lensNode)
    }

    private static func addTaillight(to parent: SCNNode, x: Float) {
        let light = roundedBox(width: 0.36, height: 0.1, length: 0.07, chamfer: 0.03, material: {
            let m = mat(UIColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1), metalness: 0.2, roughness: 0.3)
            m.emission.contents = UIColor(red: 1.0, green: 0.08, blue: 0.08, alpha: 1)
            return m
        }())
        light.position = SCNVector3(x, 0.54, -2.22)
        light.name = VehicleArea.misc.rawValue
        parent.addChildNode(light)
    }

    private static func addMirror(to parent: SCNNode, x: Float) {
        let arm = roundedBox(
            width: 0.08,
            height: 0.05,
            length: 0.14,
            chamfer: 0.02,
            material: mat(UIColor(white: 0.12, alpha: 1), metalness: 0.55, roughness: 0.35)
        )
        arm.position = SCNVector3(x, 0.76, 0.55)
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
        let pivot = SCNNode()
        pivot.name = VehicleArea.wheels.rawValue
        pivot.position = SCNVector3(x, 0.36, z)
        //larger hit target so any wheel is easy to tap
        pivot.physicsBody = nil
        parent.addChildNode(pivot)

        let tire = SCNTube(innerRadius: 0.24, outerRadius: 0.37, height: 0.28)
        tire.firstMaterial = rubber.copy() as? SCNMaterial ?? rubber
        let tireNode = SCNNode(geometry: tire)
        tireNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tireNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(tireNode)

        //larger rim face
        let disc = SCNCylinder(radius: 0.25, height: 0.08)
        disc.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let discNode = SCNNode(geometry: disc)
        discNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        discNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(discNode)

        //7-spoke design
        for i in 0..<7 {
            let spoke = SCNBox(width: 0.055, height: 0.44, length: 0.048, chamferRadius: 0.01)
            spoke.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
            let spokeNode = SCNNode(geometry: spoke)
            spokeNode.eulerAngles = SCNVector3(Float(i) * (.pi * 2 / 7), 0, 0)
            spokeNode.name = VehicleArea.wheels.rawValue
            pivot.addChildNode(spokeNode)
        }

        //outer rim ring for more presence
        let ring = SCNTube(innerRadius: 0.23, outerRadius: 0.255, height: 0.09)
        ring.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let ringNode = SCNNode(geometry: ring)
        ringNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        ringNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(ringNode)

        let cap = SCNSphere(radius: 0.07)
        cap.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let capNode = SCNNode(geometry: cap)
        capNode.scale = SCNVector3(0.75, 0.75, 0.4)
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
            chamferRadius: min(chamfer, min(width, height, length) * 0.4)
        )
        geometry.chamferSegmentCount = 10
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
