import SceneKit
import UIKit

/// Blank-slate sport sedan silhouette (S4-inspired proportions, no branding).
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"

    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        //fully clear so the SwiftUI page shows through
        scene.background.contents = UIColor.clear

        let sedan = makeSedan()
        sedan.name = sedanNodeName
        scene.rootNode.addChildNode(sedan)

        //soft contact shadow only
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
        shadowNode.opacity = 0.22
        scene.rootNode.addChildNode(shadowNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 480
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1200
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 380
        fill.eulerAngles = SCNVector3(-0.2, -1.0, 0)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 260
        rim.eulerAngles = SCNVector3(0.15, 2.5, 0)
        scene.rootNode.addChildNode(rim)

        return scene
    }

    private static func makeSedan() -> SCNNode {
        let root = SCNNode()

        let paint = mat(UIColor(white: 0.82, alpha: 1), metalness: 0.62, roughness: 0.28)
        let dark = mat(UIColor(white: 0.12, alpha: 1), metalness: 0.45, roughness: 0.4)
        let glass = mat(
            UIColor(red: 0.45, green: 0.58, blue: 0.68, alpha: 1),
            metalness: 0.1,
            roughness: 0.08
        )
        glass.transparency = 0.55
        let rubber = mat(UIColor(white: 0.07, alpha: 1), metalness: 0.05, roughness: 0.92)
        let chrome = mat(UIColor(white: 0.88, alpha: 1), metalness: 0.95, roughness: 0.16)

        //main body — extruded side silhouette (reads as a real car, not stacked boxes)
        let body = extrudedProfile(
            path: sedanSideProfile(),
            depth: 1.86,
            material: paint,
            area: .body
        )
        root.addChildNode(body)

        //subtle shoulder / beltline strip for more 3D form
        let shoulder = extrudedProfile(
            path: shoulderProfile(),
            depth: 1.92,
            material: paint,
            area: .body
        )
        shoulder.position.y = 0.02
        shoulder.opacity = 0.95
        root.addChildNode(shoulder)

        //cabin glass insert (slightly narrower)
        let greenhouse = extrudedProfile(
            path: greenhouseProfile(),
            depth: 1.72,
            material: glass,
            area: .body
        )
        greenhouse.position.y = 0.01
        root.addChildNode(greenhouse)

        //hood panel (drivetrain tap + open animation)
        let hoodPivot = SCNNode()
        hoodPivot.name = "hoodPivot"
        hoodPivot.position = SCNVector3(0, 0.70, 0.55)
        root.addChildNode(hoodPivot)

        let hood = roundedBox(width: 1.78, height: 0.05, length: 1.35, chamfer: 0.04, material: paint)
        hood.position = SCNVector3(0, 0.01, 0.68)
        hood.name = VehicleArea.drivetrain.rawValue
        hoodPivot.addChildNode(hood)

        let engine = roundedBox(width: 0.7, height: 0.32, length: 0.7, chamfer: 0.04, material: dark)
        engine.position = SCNVector3(0, 0.42, 1.2)
        engine.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(engine)

        //front lower lip
        let frontLip = roundedBox(width: 1.7, height: 0.1, length: 0.22, chamfer: 0.04, material: dark)
        frontLip.position = SCNVector3(0, 0.16, 2.28)
        frontLip.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(frontLip)

        addHeadlight(to: root, x: -0.68)
        addHeadlight(to: root, x: 0.68)

        //trunk panel (misc tap + open animation)
        let trunkPivot = SCNNode()
        trunkPivot.name = "trunkPivot"
        trunkPivot.position = SCNVector3(0, 0.74, -1.15)
        root.addChildNode(trunkPivot)

        let trunk = roundedBox(width: 1.72, height: 0.05, length: 0.85, chamfer: 0.04, material: paint)
        trunk.position = SCNVector3(0, 0.01, -0.40)
        trunk.name = VehicleArea.misc.rawValue
        trunkPivot.addChildNode(trunk)

        let rearLip = roundedBox(width: 1.7, height: 0.1, length: 0.2, chamfer: 0.04, material: dark)
        rearLip.position = SCNVector3(0, 0.16, -2.28)
        rearLip.name = VehicleArea.misc.rawValue
        root.addChildNode(rearLip)

        addTaillight(to: root, x: -0.72)
        addTaillight(to: root, x: 0.72)

        //side mirrors — generic, tiny
        addMirror(to: root, x: -0.95)
        addMirror(to: root, x: 0.95)

        addWheel(to: root, x: -0.93, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.93, z: 1.32, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: -0.93, z: -1.35, rubber: rubber, chrome: chrome)
        addWheel(to: root, x: 0.93, z: -1.35, rubber: rubber, chrome: chrome)

        return root
    }

    // MARK: - Profiles (side view: x = length front+, y = height)

    /// Sport-sedan outline loosely based on a 2022 S4 stance — long hood, set-back cabin, short deck.
    private static func sedanSideProfile() -> UIBezierPath {
        let path = UIBezierPath()

        //front lower lip → nose
        path.move(to: CGPoint(x: 2.30, y: 0.14))
        path.addLine(to: CGPoint(x: 2.38, y: 0.28))
        path.addQuadCurve(
            to: CGPoint(x: 2.20, y: 0.52),
            controlPoint: CGPoint(x: 2.42, y: 0.44)
        )
        //hood line
        path.addQuadCurve(
            to: CGPoint(x: 0.78, y: 0.70),
            controlPoint: CGPoint(x: 1.55, y: 0.76)
        )
        //windshield rake
        path.addQuadCurve(
            to: CGPoint(x: 0.22, y: 1.16),
            controlPoint: CGPoint(x: 0.55, y: 1.02)
        )
        //roof
        path.addQuadCurve(
            to: CGPoint(x: -1.05, y: 1.20),
            controlPoint: CGPoint(x: -0.40, y: 1.26)
        )
        //rear window
        path.addQuadCurve(
            to: CGPoint(x: -1.55, y: 0.86),
            controlPoint: CGPoint(x: -1.35, y: 1.08)
        )
        //trunk deck
        path.addLine(to: CGPoint(x: -2.10, y: 0.78))
        //rear fascia
        path.addQuadCurve(
            to: CGPoint(x: -2.34, y: 0.42),
            controlPoint: CGPoint(x: -2.38, y: 0.68)
        )
        path.addLine(to: CGPoint(x: -2.28, y: 0.14))

        //bottom + wheel wells (rear → front)
        path.addLine(to: CGPoint(x: -1.72, y: 0.14))
        path.addQuadCurve(
            to: CGPoint(x: -0.98, y: 0.14),
            controlPoint: CGPoint(x: -1.35, y: 0.58)
        )
        path.addLine(to: CGPoint(x: 0.95, y: 0.14))
        path.addQuadCurve(
            to: CGPoint(x: 1.70, y: 0.14),
            controlPoint: CGPoint(x: 1.32, y: 0.58)
        )
        path.addLine(to: CGPoint(x: 2.30, y: 0.14))
        path.close()
        return path
    }

    private static func shoulderProfile() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.05, y: 0.48))
        path.addLine(to: CGPoint(x: 0.85, y: 0.62))
        path.addLine(to: CGPoint(x: 0.35, y: 0.62))
        path.addLine(to: CGPoint(x: -1.50, y: 0.66))
        path.addLine(to: CGPoint(x: -2.05, y: 0.62))
        path.addLine(to: CGPoint(x: -2.05, y: 0.52))
        path.addLine(to: CGPoint(x: 2.05, y: 0.40))
        path.close()
        return path
    }

    private static func greenhouseProfile() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.70, y: 0.74))
        path.addLine(to: CGPoint(x: 0.20, y: 1.12))
        path.addQuadCurve(
            to: CGPoint(x: -1.00, y: 1.14),
            controlPoint: CGPoint(x: -0.40, y: 1.20)
        )
        path.addLine(to: CGPoint(x: -1.42, y: 0.88))
        path.addLine(to: CGPoint(x: -1.35, y: 0.74))
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
        shape.chamferRadius = 0.025
        shape.firstMaterial = material.copy() as? SCNMaterial ?? material
        shape.firstMaterial?.isDoubleSided = false

        let node = SCNNode(geometry: shape)
        //path is in XY (length × height); extrusion along Z → rotate so nose faces +Z
        node.eulerAngles.y = .pi / 2
        node.name = area.rawValue
        return node
    }

    // MARK: - Details

    private static func addHeadlight(to parent: SCNNode, x: Float) {
        let housing = SCNSphere(radius: 0.10)
        housing.segmentCount = 28
        let housingMat = mat(UIColor(white: 0.93, alpha: 1), metalness: 0.15, roughness: 0.12)
        housingMat.emission.contents = UIColor(white: 0.45, alpha: 1)
        housing.firstMaterial = housingMat

        let node = SCNNode(geometry: housing)
        node.scale = SCNVector3(1.5, 0.55, 0.45)
        node.position = SCNVector3(x, 0.48, 2.18)
        node.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(node)

        let lens = SCNSphere(radius: 0.045)
        let lensMat = mat(UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1), metalness: 0.05, roughness: 0.08)
        lensMat.emission.contents = UIColor(red: 1, green: 0.96, blue: 0.85, alpha: 1)
        lens.firstMaterial = lensMat
        let lensNode = SCNNode(geometry: lens)
        lensNode.position = SCNVector3(x, 0.48, 2.24)
        lensNode.name = VehicleArea.drivetrain.rawValue
        parent.addChildNode(lensNode)
    }

    private static func addTaillight(to parent: SCNNode, x: Float) {
        let light = roundedBox(width: 0.36, height: 0.1, length: 0.07, chamfer: 0.03, material: {
            let m = mat(UIColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1), metalness: 0.2, roughness: 0.3)
            m.emission.contents = UIColor(red: 0.9, green: 0.05, blue: 0.05, alpha: 1)
            return m
        }())
        light.position = SCNVector3(x, 0.55, -2.22)
        light.name = VehicleArea.misc.rawValue
        parent.addChildNode(light)
    }

    private static func addMirror(to parent: SCNNode, x: Float) {
        let arm = roundedBox(
            width: 0.08,
            height: 0.05,
            length: 0.14,
            chamfer: 0.02,
            material: mat(UIColor(white: 0.75, alpha: 1), metalness: 0.5, roughness: 0.35)
        )
        arm.position = SCNVector3(x, 0.78, 0.55)
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
        pivot.position = SCNVector3(x, 0.34, z)
        parent.addChildNode(pivot)

        let tire = SCNTube(innerRadius: 0.21, outerRadius: 0.35, height: 0.26)
        tire.firstMaterial = rubber.copy() as? SCNMaterial ?? rubber
        let tireNode = SCNNode(geometry: tire)
        tireNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tireNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(tireNode)

        let disc = SCNCylinder(radius: 0.21, height: 0.07)
        disc.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let discNode = SCNNode(geometry: disc)
        discNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        discNode.name = VehicleArea.wheels.rawValue
        pivot.addChildNode(discNode)

        for i in 0..<5 {
            let spoke = SCNBox(width: 0.048, height: 0.38, length: 0.04, chamferRadius: 0.008)
            spoke.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
            let spokeNode = SCNNode(geometry: spoke)
            spokeNode.eulerAngles = SCNVector3(Float(i) * (.pi * 2 / 5), 0, 0)
            spokeNode.name = VehicleArea.wheels.rawValue
            pivot.addChildNode(spokeNode)
        }

        let cap = SCNSphere(radius: 0.055)
        cap.firstMaterial = chrome.copy() as? SCNMaterial ?? chrome
        let capNode = SCNNode(geometry: cap)
        capNode.scale = SCNVector3(0.7, 0.7, 0.4)
        capNode.position = SCNVector3(x > 0 ? 0.05 : -0.05, 0, 0)
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
