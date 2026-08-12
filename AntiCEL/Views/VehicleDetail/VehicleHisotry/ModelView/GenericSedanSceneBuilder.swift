import SceneKit
import UIKit

/// Builds a blank-slate generic sedan from primitives (no brand cues).
enum GenericSedanSceneBuilder {

    static let sedanNodeName = "sedan"

    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.secondarySystemBackground

        let sedan = makeSedan()
        sedan.name = sedanNodeName
        scene.rootNode.addChildNode(sedan)

        //soft ground shadow disc
        let ground = SCNCylinder(radius: 3.2, height: 0.02)
        ground.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.08)
        ground.firstMaterial?.lightingModel = .constant
        let groundNode = SCNNode(geometry: ground)
        groundNode.position = SCNVector3(0, -0.01, 0)
        scene.rootNode.addChildNode(groundNode)

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
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 350
        fill.eulerAngles = SCNVector3(-0.3, -0.8, 0)
        scene.rootNode.addChildNode(fill)

        return scene
    }

    private static func makeSedan() -> SCNNode {
        let root = SCNNode()

        let paint = mat(UIColor.systemGray3)
        let darkPaint = mat(UIColor.systemGray2)
        let glass = mat(UIColor.systemTeal.withAlphaComponent(0.35), metalness: 0.1, roughness: 0.05)
        let rubber = mat(UIColor.darkGray)
        let rim = mat(UIColor.systemGray)

        //lower body rocker
        let rocker = box(width: 1.85, height: 0.28, length: 4.2, material: darkPaint)
        rocker.position = SCNVector3(0, 0.28, 0)
        rocker.name = VehicleArea.body.rawValue
        root.addChildNode(rocker)

        //main cabin / greenhouse base
        let cabin = box(width: 1.75, height: 0.55, length: 2.15, material: paint)
        cabin.position = SCNVector3(0, 0.72, -0.05)
        cabin.name = VehicleArea.body.rawValue
        root.addChildNode(cabin)

        //roof
        let roof = box(width: 1.55, height: 0.12, length: 1.7, material: paint)
        roof.position = SCNVector3(0, 1.05, -0.05)
        roof.name = VehicleArea.body.rawValue
        root.addChildNode(roof)

        //windows (visual only, still body taps)
        let sideGlassL = box(width: 0.04, height: 0.32, length: 1.8, material: glass)
        sideGlassL.position = SCNVector3(-0.88, 0.82, -0.05)
        sideGlassL.name = VehicleArea.body.rawValue
        root.addChildNode(sideGlassL)

        let sideGlassR = box(width: 0.04, height: 0.32, length: 1.8, material: glass)
        sideGlassR.position = SCNVector3(0.88, 0.82, -0.05)
        sideGlassR.name = VehicleArea.body.rawValue
        root.addChildNode(sideGlassR)

        let windshield = box(width: 1.5, height: 0.35, length: 0.06, material: glass)
        windshield.position = SCNVector3(0, 0.88, 0.95)
        windshield.eulerAngles = SCNVector3(-0.45, 0, 0)
        windshield.name = VehicleArea.body.rawValue
        root.addChildNode(windshield)

        //hood / drivetrain — hinged near windshield
        let hoodPivot = SCNNode()
        hoodPivot.name = "hoodPivot"
        hoodPivot.position = SCNVector3(0, 0.55, 0.55)
        root.addChildNode(hoodPivot)

        let hood = box(width: 1.7, height: 0.1, length: 1.15, material: paint)
        hood.position = SCNVector3(0, 0, 0.55)
        hood.name = VehicleArea.drivetrain.rawValue
        hoodPivot.addChildNode(hood)

        //simple engine block under hood (shown when open / always faintly there)
        let engine = box(width: 0.7, height: 0.35, length: 0.7, material: mat(UIColor.systemGray))
        engine.position = SCNVector3(0, 0.45, 1.15)
        engine.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(engine)

        //trunk / misc — hinged near rear glass
        let trunkPivot = SCNNode()
        trunkPivot.name = "trunkPivot"
        trunkPivot.position = SCNVector3(0, 0.55, -1.05)
        root.addChildNode(trunkPivot)

        let trunk = box(width: 1.7, height: 0.12, length: 0.95, material: paint)
        trunk.position = SCNVector3(0, 0, -0.45)
        trunk.name = VehicleArea.misc.rawValue
        trunkPivot.addChildNode(trunk)

        //rear bumper volume so trunk is easier to hit from behind
        let rearBumper = box(width: 1.8, height: 0.25, length: 0.25, material: darkPaint)
        rearBumper.position = SCNVector3(0, 0.3, -2.05)
        rearBumper.name = VehicleArea.misc.rawValue
        root.addChildNode(rearBumper)

        //front bumper → drivetrain zone
        let frontBumper = box(width: 1.8, height: 0.25, length: 0.25, material: darkPaint)
        frontBumper.position = SCNVector3(0, 0.3, 2.05)
        frontBumper.name = VehicleArea.drivetrain.rawValue
        root.addChildNode(frontBumper)

        //wheels
        addWheel(to: root, x: -0.85, z: 1.25, rubber: rubber, rim: rim)
        addWheel(to: root, x: 0.85, z: 1.25, rubber: rubber, rim: rim)
        addWheel(to: root, x: -0.85, z: -1.25, rubber: rubber, rim: rim)
        addWheel(to: root, x: 0.85, z: -1.25, rubber: rubber, rim: rim)

        return root
    }

    private static func addWheel(
        to parent: SCNNode,
        x: Float,
        z: Float,
        rubber: SCNMaterial,
        rim: SCNMaterial
    ) {
        let tire = SCNCylinder(radius: 0.32, height: 0.22)
        tire.firstMaterial = rubber.copy() as? SCNMaterial ?? rubber
        let tireNode = SCNNode(geometry: tire)
        tireNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tireNode.position = SCNVector3(x, 0.32, z)
        tireNode.name = VehicleArea.wheels.rawValue
        parent.addChildNode(tireNode)

        let hub = SCNCylinder(radius: 0.14, height: 0.24)
        hub.firstMaterial = rim.copy() as? SCNMaterial ?? rim
        let hubNode = SCNNode(geometry: hub)
        hubNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        hubNode.position = SCNVector3(x, 0.32, z)
        hubNode.name = VehicleArea.wheels.rawValue
        parent.addChildNode(hubNode)
    }

    private static func box(
        width: CGFloat,
        height: CGFloat,
        length: CGFloat,
        material: SCNMaterial
    ) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.04)
        //copy so selection highlights do not bleed across shared materials
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
