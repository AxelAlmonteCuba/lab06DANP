//
//  QRScannerDelegate.swift
//  Lab_06
//
//  Created by Axel Almonte on 4/11/24.
//

import SwiftUI
import AVKit

class QRScannerDelegate: NSObject , ObservableObject, AVCaptureMetadataOutputObjectsDelegate{
    @Published var scannedCode: String?
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaObject = metadataObjects.first{
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else {return}
            guard let Code = readableObject.stringValue else{return }
            print(Code)
            scannedCode = Code
        }
    }
}


