//
//  TTNativeCameraOutputView.swift
//  TTCamera
//
//  Created by hong on 2023/1/8.
//

import Foundation
import AVFoundation

open class TTNativeCameraPreiew: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    func bindSession(_ session: AVCaptureSession) {
        previewLayer = .init(session: session)
        layer.insertSublayer(previewLayer, at: 0)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = self.bounds
    }
}
