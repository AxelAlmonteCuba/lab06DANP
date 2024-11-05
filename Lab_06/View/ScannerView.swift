//
//  ScannerView.swift
//  Lab_06
//
//  Created by Axel Almonte on 4/11/24.
//

import SwiftUI
import AVKit
struct ScannerView: View {
    @State private var isSacanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: Permission = .idle
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    @State private var errorMessage : String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var openURL
    
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State private var scannedCode: String = ""
    var body: some View {
        VStack(spacing:0){
            Button{
                
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Color("Blue"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Coloca el QR en el area determinada")
                .font(.title3)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 20)
            Text("se escaneara Automaticamente")
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer(minLength: 0)
            
            //escanner
            GeometryReader{
                let size = $0.size
                
                ZStack{
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.97)
                    ForEach(0...4 , id: \.self){ index in
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                            .trim(from: 0.61, to: 0.64)
                            .stroke(Color("Blue"), style: StrokeStyle(lineWidth: 5, lineCap:  .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                    }
                }
                .frame(width: size.width, height: size.height)
                .overlay(alignment: .top, content:{
                    Rectangle()
                        .fill(Color("Blue"))
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x: 0 , y: isSacanning ? 15:-15)
                        .offset(y: isSacanning ? size.width:  0)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            
            Button{
                if !session.isRunning && cameraPermission == .approved{
                    reactivateCamer()
                    activateScannerAnimation()
                }
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            Spacer(minLength: 45)
            
        }
        .padding(15)
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError){
            if cameraPermission == .denied{
                Button("Ajustes"){
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingURL = URL(string: settingsString){
                        openURL(settingURL)
                    }
                }
                Button("Cancelar", role: .cancel){
                    
                }
            }
            
        }
        .onChange(of: qrDelegate.scannedCode) {  newValue in
            if let code = newValue{
                scannedCode = code
                session.stopRunning()
                DesactivateScannerAnimation()
                qrDelegate.scannedCode = nil
            }
        }
        
        
    }
    func reactivateCamer(){
        DispatchQueue.global(qos: .background).async{
            session.startRunning()
        }
    }
    func activateScannerAnimation(){
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)){
            isSacanning = true
        }
    }
    
    func DesactivateScannerAnimation(){
        withAnimation(.easeInOut(duration: 0.85)){
            isSacanning = false
        }
    }
    func checkCameraPermission() {
        Task{
            switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty{
                    setupCamera()
                }else{
                    session.startRunning()
                }
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video){
                    cameraPermission = .approved
                    setupCamera()
                }
                else{
                    cameraPermission = .denied
                    
                    presentError("Por favor dar permisos a la aplicaciion")
                }
            case .denied, .restricted:
                cameraPermission = .denied
                presentError("Por favor dar permisos a la aplicaciion")

            default: break
            }
        }}
    
    func setupCamera(){
        do {
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes:  [.builtInWideAngleCamera] , mediaType: .video, position: .back).devices.first else{ presentError("Error de dispositivo")
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else{
                presentError("error input/output")
                return

            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            qrOutput.metadataObjectTypes =  [.qr]
            
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            DispatchQueue.global(qos: .background).async{
                session.startRunning()
            }
            activateScannerAnimation()
        }catch{
            presentError(error.localizedDescription)
        }
    }
    func presentError(_ message: String){
        errorMessage = message
        showError.toggle()
    }
}
