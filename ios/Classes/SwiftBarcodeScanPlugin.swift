import Flutter
import UIKit
import SwiftProtobuf
import AVFoundation

public class SwiftBarcodeScanPlugin: NSObject, FlutterPlugin, BarcodeScannerViewControllerDelegate {
    
    private var result: FlutterResult?
    private var hostViewController: UIViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "de.mintware.barcode_scan", binaryMessenger: registrar.messenger())
        let instance = SwiftBarcodeScanPlugin()
        instance.hostViewController = UIApplication.shared.delegate?.window??.rootViewController
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        if ("scan" == call.method) {
            let configuration: Configuration? = getPayload(call: call)
            showBarcodeView(config: configuration)}
        else if ("numberOfCameras" == call.method) {
            result(AVCaptureDevice.devices(for: .video).count)
        } else if ("requestCameraPermission" == call.method) {
            result(false)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func showBarcodeView(config: Configuration? = nil) {
        let scannerViewController = BarcodeScannerViewController()
        
        let navigationController = UINavigationController(rootViewController: scannerViewController)
        
        if #available(iOS 13.0, *) {
            navigationController.modalPresentationStyle = .fullScreen
        }
        
        if let config = config {
            scannerViewController.config = config
        }
        scannerViewController.delegate = self
        
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        hostViewController = self.getVisibleViewControllerFrom(vc: rootViewController!)
        
        hostViewController?.present(navigationController, animated: false)
    }
    
    private func getVisibleViewControllerFrom(vc:UIViewController) -> UIViewController {
        if let navigationController = vc as? UINavigationController,
            let visibleController = navigationController.visibleViewController  {
            return self.getVisibleViewControllerFrom( vc: visibleController )
        } else if let tabBarController = vc as? UITabBarController,
            let selectedTabController = tabBarController.selectedViewController {
            return self.getVisibleViewControllerFrom(vc: selectedTabController )
        } else {
            if let presentedViewController = vc.presentedViewController {
                return self.getVisibleViewControllerFrom(vc: presentedViewController)
            } else {
                return vc
            }
        }
    }
    
    private func getPayload<T : SwiftProtobuf.Message>(call: FlutterMethodCall) -> T? {
        
        if(call.arguments == nil || !(call.arguments is FlutterStandardTypedData)) {
            return nil
        }
        do {
            let configuration = try T(serializedData: (call.arguments as! FlutterStandardTypedData).data)
            return configuration
        } catch {
        }
        return nil
    }
    
    func didScanBarcodeWithResult(_ controller: BarcodeScannerViewController?, scanResult: ScanResult) {
      do {
        result?(try scanResult.serializedData())
      } catch {
        result?(FlutterError(code: "err_serialize", message: "Failed to serialize the result", details: nil))
      }
    }
    
    func didFailWithErrorCode(_ controller: BarcodeScannerViewController?, errorCode: String) {
        result?(FlutterError(code: errorCode, message: nil, details: nil))
    }
}

