//
//  TTNativeCamera.swift
//  Pods-TTCamera_Example
//
//  Created by hong on 2023/1/8.
//

import Foundation
import AVFoundation
public protocol TTNativeCameraDelegate {
    func cameraCapture(_ capture: TTNativeCamera, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime)
}

open class TTNativeCamera: NSObject {
    public struct Config {
        let preset: AVCaptureSession.Preset = .vga640x480
        let position: AVCaptureDevice.Position = .front
    }
    private var config = TTNativeCamera.Config()
    
    
    private let delegateTable = NSHashTable<NSObject>.init(options: .weakMemory)
    public var delegate: NSObject? {
        didSet {
            if let delegate = delegate {
                delegateTable.add(delegate)
            }
        }
    }
    
    
    
    private let captureSession = AVCaptureSession()
    private var currentPositon: AVCaptureDevice.Position = .front
    private let captureQueue: DispatchQueue = DispatchQueue(label: "TTNativeCameraQueue")
    private var currentOutput: AVCaptureVideoDataOutput? {
        if let outputs = self.captureSession.outputs as? [AVCaptureVideoDataOutput] {
            return outputs.first
        } else {
            return nil
        }
    }
    
    public let localPreview =  TTNativeCameraPreiew()
    
    
    public init(_ configuation: ((TTNativeCamera.Config) -> ())) {
        super.init()
        configuation(self.config)
        setupDefaultConfig()
        setupSession()
    }
    
    private func setupDefaultConfig() {
        currentPositon = config.position
    }
    
    private func setupSession() {
        captureSession.usesApplicationAudioSession = false
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }
        
        // 本地预览绑定session
        localPreview.bindSession(captureSession)
    }
    
    // 切换设备
    private func changeCaptureDevice(toIndex index: Int, ofSession captureSession: AVCaptureSession) {
        guard let captureDevice = fetchCaptureDevice(atIndex: index) else {
            return
        }
        
        let currentInputs = captureSession.inputs as? [AVCaptureDeviceInput]
        let currentInput = currentInputs?.first
        
        // 重复设备，就返回
        if let currentInputName = currentInput?.device.localizedName,
           currentInputName == captureDevice.uniqueID {
            return
        }
        
        // 新的输入源
        guard let newInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.beginConfiguration()
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        
        captureSession.commitConfiguration()
    }
    
    
    func fetchCaptureDevice(atIndex index: Int) -> AVCaptureDevice? {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: currentPositon)
        
        // 可用的设备
        let devices = deviceDiscoverySession.devices
        
        let count = devices.count
        guard count > 0, index >= 0 else {
            return nil
        }
        
        // 越界了就取最后一个，没有越界取下标
        if index >= count {
            return devices.last
        } else {
            return devices[index]
        }
    }
    
    deinit {
        captureSession.stopRunning()
    }
}

public extension TTNativeCamera {
    // 开始采集
    func startCapture() {
        guard let currentOutput = currentOutput else {
            return
        }
        
        // 采样输出代理
        currentOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        // 选择设备
        captureQueue.async { [weak self]  in guard let self = self else { return }
            self.changeCaptureDevice(toIndex: 0, ofSession: self.captureSession)
            self.captureSession.beginConfiguration()
            
            let preset = AVCaptureSession.Preset.vga640x480
            
            if self.captureSession.canSetSessionPreset(preset) {
                self.captureSession.sessionPreset = preset
            }
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    // 结束采集
    func stopCapture() {
        currentOutput?.setSampleBufferDelegate(nil, queue: nil)
        captureQueue.async { [weak self]  in guard let self = self else { return }
            self.captureSession.stopRunning()
        }
    }
    
    // 切换摄像头方向
    func switchPosition(_ position: AVCaptureDevice.Position) {
        currentPositon = position
        changeCaptureDevice(toIndex: 0, ofSession: captureSession)
    }
}


// MARK: - 原生画面输出
extension TTNativeCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        DispatchQueue.main.async {[weak self]  in guard let self = self else { return }
            self.delegateTable.allObjects.forEach { delegate in
                if let delegate = delegate as? TTNativeCameraDelegate {
                    delegate.cameraCapture(self, didOutputSampleBuffer: pixelBuffer, rotation: 90, timeStamp: time)
                }
            }
        }
    }
}
