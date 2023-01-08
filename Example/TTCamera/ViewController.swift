//
//  ViewController.swift
//  TTCamera
//
//  Created by imbatao@outlook.com on 01/08/2023.
//  Copyright (c) 2023 imbatao@outlook.com. All rights reserved.
//

import UIKit
import TTCamera
import AVFoundation
import SnapKit
class ViewController: UIViewController {

    var camera: TTNativeCamera!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = TTNativeCamera.init(delegate: self, { config in
            
        })
        
        view.addSubview(camera.localPreview)
        camera.localPreview.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    var positon: Int = 0
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        positon += 1
        camera.switchPosition(positon % 2 == 0 ? .front : .back)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera.startCapture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stopCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: TTNativeCameraDelegate {
    func cameraCapture(_ capture: TTCamera.TTNativeCamera, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        
    }
    
}
