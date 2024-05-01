//
//  MainViewController.swift
//  ChessboardDetection
//
//  Created by HU Siyan on 4/4/2024.
//

import os
import UIKit
import CoreML
import CoreMedia
import Vision
import MetalPerformanceShaders

class MainViewController: UIViewController {
    
    @IBOutlet var videoPreview: UIView!
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
    
    var videoCapture: VideoCapture!
    var currentBuffer: CVPixelBuffer?
    
    let maxBoundingBoxViews = 10
    var boundingBoxViews = [BoundingBoxView]()
    var colors: [String: UIColor] = [:]
    
    let coreMLModel = try! best()
    
    lazy var visionmodel: VNCoreMLModel = {
      do {
        return try VNCoreMLModel(for: coreMLModel.model)
      } catch {
        fatalError("Failed to create VNCoreMLModel: \(error)")
      }
    }()
    
    lazy var visionRequest: VNCoreMLRequest = {
      let request = VNCoreMLRequest(model: visionmodel, completionHandler: {
        [weak self] request, error in
        self?.processObservations(for: request, error: error)
      })
      request.imageCropAndScaleOption = .scaleFill
      return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpBoundingBoxViews()
        setUpCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
//            if let results = request.results as? [VNRecognizedObjectObservation] {
//                self.show(predictions: results)
//            } else {
//                self.show(predictions: [])
//            }
            if let results = request.results as? [VNCoreMLFeatureValueObservation] {
                for i in 0..<results.count {
                    let prediction = results[i]
                    let detectedFeatures = prediction.featureValue.multiArrayValue! as MLMultiArray
                    self.parseFeature(feature: detectedFeatures, i: i)
                }
            } else {
                
            }
        }
    }
    
    func sigmoid(z: Double) -> Double {
        return 1.0 / (1.0 + exp(-z))
    }

    func parseFeature(feature: MLMultiArray, i: Int) {
        var probMaxIdx = 0
        var maxProb : Float = 0
        var box_x : Float = 0
        var box_y : Float = 0
        var box_width : Float = 0
        var box_height : Float = 0
        
        for j in 0...feature.shape[2].intValue-2{
          let key = [0,4,j] as [NSNumber]
          let nextKey = [0,4,j+1] as [NSNumber]
          if(feature[key].floatValue < feature[nextKey].floatValue){
              if(maxProb < feature[nextKey].floatValue){
                  probMaxIdx = j+1
                  let xKey = [0,0,probMaxIdx] as [NSNumber]
                  let yKey = [0,1,probMaxIdx] as [NSNumber]
                  let widthKey = [0,2,probMaxIdx] as [NSNumber]
                  let heightKey = [0,3,probMaxIdx] as [NSNumber]
                  maxProb = feature[nextKey].floatValue
                  box_width = feature[widthKey].floatValue
                  box_height = feature[heightKey].floatValue
                  
                  box_x = feature[xKey].floatValue - (box_width/2)
                  box_y = feature[yKey].floatValue - (box_height/2)
              }
          }
        }
        var boundingBox = CGRect(x: 0,y: 0,width: 10,height: 10)
        boundingBox = CGRect(x: CGFloat(box_x)
                             ,y: CGFloat(box_y)
                             ,width: CGFloat(box_width)
                             ,height: CGFloat(box_height))
        
        let width = view.bounds.width
        let height = width * 16 / 9
        let offsetY = (view.bounds.height - height) / 2
        
        let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)
        let rect = boundingBox.applying(scale).applying(transform)
        
        print(maxProb, rect)
        if (maxProb > 0.3) {
            let color = UIColor.red
            let label = String(format: "%@ %.3f", "chessboard", maxProb)
            boundingBoxViews[i].show(frame: boundingBox, label: label, color: color)
        } else {
            boundingBoxViews[i].hide()
        }
    }
    
    func predict(sampleBuffer: CMSampleBuffer) {
        if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            currentBuffer = pixelBuffer
            var options: [VNImageOption : Any] = [:]
            if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                options[.cameraIntrinsics] = cameraIntrinsicMatrix
            }
            
            let ciContext = CIContext()
            var resizedBuffer: CVPixelBuffer?
            resizedBuffer = createPixelBuffer(width: 640, height: 640, pixelFormat: kCVPixelFormatType_32BGRA)
            resizePixelBuffer(srcPixelBuffer: pixelBuffer, targetWidth: 640, targetHeight: 640, output:resizedBuffer!, context:ciContext)
            
//            let ciImage = CIImage(cvPixelBuffer: resizedBuffer!)
//            let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
//            let handler = VNImageRequestHandler(ciImage: ciImage)
            
            let handler = VNImageRequestHandler(cvPixelBuffer: resizedBuffer!, orientation: .up, options: options)
            do {
                try handler.perform([self.visionRequest])
            } catch {
                print("Failed to perform Vision request: \(error)")
            }
            currentBuffer = nil
        }
    }
    
    func metalCompatiblityAttributes() -> [String: Any] {
        let attributes: [String: Any] = [
            String(kCVPixelBufferMetalCompatibilityKey): true,
            String(kCVPixelBufferOpenGLCompatibilityKey): true,
            String(kCVPixelBufferIOSurfacePropertiesKey): [
                String(kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey): true,
                String(kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey): true,
                String(kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey): true
            ]
        ]
        return attributes
    }
    
    public func createPixelBuffer(width: Int, height: Int, pixelFormat: OSType) -> CVPixelBuffer? {
        let attributes = metalCompatiblityAttributes() as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes, &pixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create pixel buffer", status)
            return nil
        }
        return pixelBuffer
    }
    
    func resizePixelBuffer(srcPixelBuffer: CVPixelBuffer,
                           targetWidth: Int, targetHeight: Int, output: CVPixelBuffer, context: CIContext) {
        
        let ciImage = CIImage(cvPixelBuffer: srcPixelBuffer)
        let sx = CGFloat(targetWidth) / CGFloat(CVPixelBufferGetWidth(srcPixelBuffer))
        let sy = CGFloat(targetHeight) / CGFloat(CVPixelBufferGetHeight(srcPixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        context.render(scaledImage, to: output)
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    func setUpBoundingBoxViews() {
        for _ in 0..<maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        // The label names are stored inside the MLModel's metadata.
        guard let userDefined = coreMLModel.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as? [String: String],
              let allLabels = userDefined["names"] else {
            fatalError("Missing metadata")
        }
        let labels = allLabels.components(separatedBy: ",")
        // Assign random colors to the classes.
        for label in labels {
            colors[label] = UIColor(red: CGFloat.random(in: 0...1),
                                    green: CGFloat.random(in: 0...1),
                                    blue: CGFloat.random(in: 0...1),
                                    alpha: 1)
        }
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        
        videoCapture.setUp(sessionPreset: .hd1280x720) {success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxViews {
                    box.addToLayer(self.videoPreview.layer)
                }
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
}

extension MainViewController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
      predict(sampleBuffer: sampleBuffer)
  }
}
