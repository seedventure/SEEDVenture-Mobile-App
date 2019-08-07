import UIKit
import Flutter


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    
    
    let aesChannel = FlutterMethodChannel(name: "seedventure.io/aes",
                                             binaryMessenger: controller)
    
    aesChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: FlutterResult) -> Void in
        
        // Load the AES module
        let AES = CryptoJS.AES()
        
        var map = call.arguments as? Dictionary<String, String>
        
        let password = map?["realPass"]

        
        if(call.method == "encrypt"){
            let plainData = map?["plainData"]
            let encrypted = AES.encrypt(plainData!, password: password!)
            result(encrypted)
        }
        
        if(call.method == "decrypt"){
            let encrypted = map?["encrypted"]
            let decrypted = AES.decrypt(encrypted!, password: password!)
            result(decrypted)
        }
        
       
    })
    
    let exportChannel = FlutterMethodChannel(name: "seedventure.io/export_config",
                                             binaryMessenger: controller)
    
    exportChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: FlutterResult) -> Void in
        guard call.method == "exportConfig" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        var map = call.arguments as? Dictionary<String, String>
        let add = map?["path"]
        
        self.exportFile(result: result, path: add!)
    })
    
   
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func exportFile(result: FlutterResult, path: String){
        
        let url = URL(fileURLWithPath: path)
        
        let docPick: UIDocumentPickerViewController = UIDocumentPickerViewController.init(url: url, in: .exportToService)
        docPick.delegate = self
        docPick.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        controller.present(docPick, animated: true, completion: nil)
        result(true)
        
        
    }
}
