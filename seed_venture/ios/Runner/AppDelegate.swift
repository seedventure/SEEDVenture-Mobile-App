import UIKit
import Flutter


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
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
    
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
