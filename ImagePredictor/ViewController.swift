//
//  ViewController.swift
//  ImagePredictor
//
//  Created by Rodrigo Yukio Okido on 04/05/22.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // Label of output result
    @IBOutlet weak var imagePredictorLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    /**
     Model used: SqueezeNet - (developer.apple.com/machine-learning/models/)
     CaptureOutput function classifies the image and makes a prediction about what the element being pointed by camera represents.
     The output printed is composed by the first result confidence and identifier.
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        let config = MLModelConfiguration()
        guard let coreMLModel = try? SqueezeNet(configuration: config),
              let model = try? VNCoreMLModel(for: coreMLModel.model) else {return}
        let request = VNCoreMLRequest(model: model) { (finished, error) in
            
            guard let results = finished.results as? [VNClassificationObservation] else {return}
            
            guard let firstResult = results.first else {return}
            DispatchQueue.main.async {
                self.imagePredictorLabel.text = "\(firstResult.confidence) - \(firstResult.identifier)"
            }
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }



}


