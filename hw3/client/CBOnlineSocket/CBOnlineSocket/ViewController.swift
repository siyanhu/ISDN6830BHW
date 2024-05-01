//
//  ViewController.swift
//  CBOnlineSocket
//
//  Created by HU Siyan on 30/4/2024.
//

import UIKit
import ARKit
import ARVideoKit
import SocketIO

class ViewController: UIViewController, RenderARDelegate, RecordARDelegate, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var starButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    
    var recorder:RecordAR?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        recorder = RecordAR(ARSceneKit: sceneView)
        recorder?.delegate = self
        recorder?.renderAR = self
        recorder?.onlyRenderWhileRecording = false
        recorder?.contentMode = .aspectFill
        recorder?.enableAdjustEnvironmentLighting = true
        recorder?.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        recorder?.deleteCacheWhenExported = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        sceneView.session.run(configuration)
        recorder?.prepare(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Pause the view's session
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        if recorder?.status == .recording {
            recorder?.stopAndExport()
        }
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARWorldTrackingConfiguration())
        
        // Switch off the orientation lock for UIViewControllers with AR Scenes
        recorder?.rest()
    }
    
    func addSurfaceAndObject(_ pntLU: SCNVector3, _ pntRD: SCNVector3) {
        print("Adding surface to ", pntLU, pntRD)
        
        let mainNode = SCNNode()
        mainNode.name = "plane"
        
        let node = SCNNode(geometry: SCNPlane(width: 4, height: 4))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.eulerAngles.x = -.pi / 2
        node.opacity = 0.25
        node.position = pntLU
        mainNode.addChildNode(node)

        guard let shipScene = SCNScene(named: "Models.scnassets/vase/vase.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: "vase", recursively: false)
        else {
            print("ERROR: initiating shipScene")
            return
        }

        shipNode.scale = SCNVector3(0.1,0.1,0.1)
        shipNode.position = SCNVector3(0, 0, 0)
        mainNode.addChildNode(shipNode)
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "plane" {
                node.removeFromParentNode()
            }
        }
        sceneView.scene.rootNode.addChildNode(mainNode)
    }
    
    func addObject(_ pntLU: SCNVector3) {
        print("Adding surface to ", pntLU)
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "vase" {
                node.removeFromParentNode()
            }
        }

        guard let shipScene = SCNScene(named: "Models.scnassets/vase/vase.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: "vase", recursively: false)
        else {
            print("ERROR: initiating shipScene")
            return
        }

        shipNode.scale = SCNVector3(0.1,0.1,0.1)
        shipNode.position = pntLU
        
        sceneView.scene.rootNode.addChildNode(shipNode)
    }
    
    func transferImagePointToScreen(_ imagePnt: CGPoint) -> CGPoint {
        let screenSize: CGRect = UIScreen.main.bounds
        let width = screenSize.width
        let height = screenSize.height
        
        let newP = self.view .convert(imagePnt, to: sceneView)
        return newP
    }

    func transferScreenPointToScene(_ screenPnt: CGPoint) -> SCNVector3 {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let virtualHit: [SCNHitTestResult] = sceneView.hitTest(screenPnt, options: hitTestOptions)
        guard let hitResult = virtualHit.first else {
            return SCNVector3(0, 0, 0)
        }
        let vector = SCNVector3(hitResult.localCoordinates.x, hitResult.localCoordinates.y, hitResult.localCoordinates.z)
        return vector
    }
    
    func convertDepthData(depthMap: CVPixelBuffer, offset: Int) -> CGFloat {
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            var convertedDepthMap: [[Float32]] = Array(
                repeating: Array(repeating: 0, count: width),
                count: height
            )
            CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
            let floatBuffer = unsafeBitCast(
                CVPixelBufferGetBaseAddress(depthMap),
                to: UnsafeMutablePointer<Float32>.self
            )
            for row in 0 ..< height {
                for col in 0 ..< width {
                    convertedDepthMap[row][col] = floatBuffer[width * row + col]
                    
                    let label = Int(Int(CGFloat(width)) * row + col)
                    if (label == offset) {
                        return CGFloat(floatBuffer[width * row + col])
                    }
                }
            }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
        return -1.0
    }
    
    func getDepthInfoAt(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        guard let frame = self.sceneView.session.currentFrame else {
            return -1
        }
        guard let depthData = frame.sceneDepth else {
            return -1
        }
        
        let depthMap = depthData.depthMap
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let size = width * height
        
        let offset = Int(CGFloat(width) * y + x)
        let d = convertDepthData(depthMap: depthMap, offset: offset)
        return CGFloat(d)
    }
}

//MARK: - IBActions
extension ViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("=================[TOUCH TEST]=================")
        let touch = touches.first
        let touchPoint = (touch?.location(in: sceneView))!
        print("Real touch:", touchPoint.x, touchPoint.y)
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let virtualHit: [SCNHitTestResult] = sceneView.hitTest(touchPoint, options: hitTestOptions)
        guard let hitResult = virtualHit.first else {
            return
        }
        var vector = SCNVector3(hitResult.localCoordinates.x, hitResult.localCoordinates.y, hitResult.localCoordinates.z)
        let depth = getDepthInfoAt(touchPoint.x, touchPoint.y)
        if (depth == -1.0) == false {
            vector = SCNVector3(vector.x, vector.y, Float(depth))
        }
        self.addObject(vector)
        print("=================[TOUCH TEST END]=================")
    }
    
    @IBAction func startDetection(_ sender: UIButton) {
        if recorder?.status == .readyToRecord {
            let image = self.recorder?.photo()
            let w = image!.size.width
            let h = image!.size.height
            let request = ImageUploader(uploadImage: image!, number: 1)
            request.uploadImage { [self] (result) in
                switch result {
                    case .success(let value):
                        if value.body!["result"] as! Int == 1 {
                            let x1 = (value.body!["x1"] as? NSNumber)?.floatValue ?? 0
                            let y1 = (value.body!["y1"] as? NSNumber)?.floatValue ?? 0
//                            let w = (value.body!["w"] as? NSNumber)?.floatValue ?? 0
//                            let h = (value.body!["h"] as? NSNumber)?.floatValue ?? 0
                            
                            print("bbox data:", x1, y1, w, h)
                            
                            var screenCenter = CGPoint(x: Double(x1), y: Double(y1))
                            
                            let screenBounds = UIScreen.main.bounds
                            let width = screenBounds.width
                            let height = screenBounds.height
                            
                            let percentX = screenCenter.x / CGFloat(w)
                            let percentY = screenCenter.y / CGFloat(h)

                            screenCenter = CGPointMake(width * percentX, height * percentY);
                            
                            DispatchQueue.main.async { [self] in
                                let screenCenter = self.view.convert(screenCenter, to: self.sceneView)
                                print("Virtual touch:", screenCenter.x, screenCenter.y)
                                var sceneCenter =  transferScreenPointToScene(screenCenter)
                                let depth = getDepthInfoAt(screenCenter.x, screenCenter.y)
                                if (depth == -1.0) == false {
                                    sceneCenter = SCNVector3(sceneCenter.x, sceneCenter.y, Float(depth))
                                }
                                if (sceneCenter.x == 0.0 || sceneCenter.y == 0.0) == false {
                                    self.addObject(sceneCenter)
                                }
                            }
                        } else {
//                            self.addSurfaceAndObject(SCNVector3(0, 0, 0), SCNVector3(0, 0.5, 0.5))
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
            }
            
            
//            let manager = SocketManager(socketURL: URL(string: "http://143.89.144.130:12345")!, config: [.log(true), .compress])
//            let socket = manager.defaultSocket
//            socket.on(clientEvent: .connect) {data, ack in
//                print("socket connected")
//            }
//            
//            socket.on("little") {data, ack in
//                socket.emitWithAck("little", imageBase64!).timingOut(after: 20) {data in
//                    print("[Response Flag]")
//                    print(data)
//                }
//            }
//            socket.connect()
        }
    }
}

//MARK: - ARVideoKit Delegate
extension ViewController {
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording.
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
}

//MARK: - ARSCNViewDelegate
extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        DispatchQueue.global().async {
//            guard let frame = self.sceneView.session.currentFrame else {
//                return
//            }
//            let depthData = frame.smoothedSceneDepth
//            print(depthData?.depthMap)
//        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
//            if node.name == "vase" {
//                let original_node_pos = node.position
//            }
//        }
    }
}
