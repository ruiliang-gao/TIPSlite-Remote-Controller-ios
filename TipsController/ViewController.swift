//
//  ViewController.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/15/21.
//

import UIKit
import CoreMotion
import MediaPlayer
import AVFoundation

class ViewController: UIViewController {
    private var audioLevel : Float = 0.0
//    private var mSensorQuat = Quaternion()
//    private var mQuat = Quaternion()
//    private var mCalibrateQuat = Quaternion()
    private var mSensorQuat = CMQauternionControl()
    private var mQuat = CMQauternionControl()
    private var mCalibrateQuat = CMQauternionControl()
    private var mCalibrated: Bool = false
    private var mFlipDown: Int = 0
    private var curSkipSend: Int = 0
    var status: String = ""
    private var mMotionStateY: Float = 0;
    private var mMotionStateX: Float = 0;
    private var mDeviceId: Int = 1
    private var mButtonState: Int = 0
    private var mStrBuilder: NSString = NSString()
    private var mSensorData: String = ""
    private var skipSendMax: Int = 0
    private var mVibrationStrength: Int = 2
    private var server = ServerConnection("", port: 0)
    

    @IBOutlet weak var delay: UITextField!
    
    @IBAction func delayEnter(_ sender: Any) {
        skipSendMax = Int(delay.text!) ?? 0
    }
    
    func addDoneButtonOnKeyboard(){
            let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            doneToolbar.barStyle = .default

            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))

            let items = [flexSpace, done]
            doneToolbar.items = items
            doneToolbar.sizeToFit()

            delay.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction(){
        delay.resignFirstResponder()
    }
        
    @IBOutlet weak var userGuide: UITextView!
    
    
    
    @IBOutlet weak var wQuaternion: UITextField!
    
    @IBOutlet weak var xQuaternion: UITextField!
    
    @IBOutlet weak var yQuaternion: UITextField!
    
    @IBOutlet weak var zQuaternion: UITextField!
    
    var motion = CMMotionManager()
    
    @IBOutlet weak var viewInstructions: UIBarButtonItem!
    
    @IBAction func viewInstructionsClick(_ sender: Any) {
        
        let vc = storyboard?.instantiateViewController(identifier: "instructionView") as! InstructionViewController
        vc.title = "Instructions Page"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBOutlet weak var userGuideBtn: UIBarButtonItem!
    
    
    @IBAction func userGuideClick(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "userguideView") as! UserGuideViewController
        vc.title = "User Guide"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBOutlet weak var userGuideView: UITextView!
    
    
    @IBOutlet weak var sliderValue: UISlider!
    
    
    @IBAction func sliderChange(_ sender: Any) {
        mVibrationStrength = Int(sliderValue.value)
    }
    
    
    @IBOutlet weak var joinButton: UIButton!
    
    @IBAction func joinServer(_ sender: Any) {
        let response = RemoteTunnel()
        if (response.serverPort != nil) && (response.serverUrl != nil) {
            server = ServerConnection.init(response.serverUrl!, port: response.serverPort!)
            server.initNetworkCommunication()
        }
        joinButton.setTitle("Connected", for: .normal)
        joinButton.isEnabled = false
        userGuideView.removeFromSuperview()
        
    }
    
    @IBOutlet weak var calibrateButton: UIButton!
    
    @IBOutlet weak var streamStatus: UILabel!
    
    
    @IBAction func calibrateAction(_ sender: Any) {
        self.mCalibrateQuat = self.mSensorQuat.inverse()
        self.mCalibrated = true
        self.mButtonState = 3
        if calibrateButton.title(for: .normal) != "Recalibrate" {
            streamStatus.text = "Calibrated Flip to start…"
        }
        calibrateButton.setTitle("Recalibrate", for: .normal)
    }
    
    @IBOutlet weak var mTouchView: DrawView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addDoneButtonOnKeyboard()
        // Do any additional setup after loading the view.
        start()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
            start()
           listenVolumeButton()
       }
       
       func listenVolumeButton(){
           
           let audioSession = AVAudioSession.sharedInstance()
           do {
               try audioSession.setActive(true, options: [])
               audioSession.addObserver(self, forKeyPath: "outputVolume",
                                        options: NSKeyValueObservingOptions.new, context: nil)
               audioLevel = audioSession.outputVolume
           } catch {
               print("Error")
           }
       }
       
       override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
           if keyPath == "outputVolume"{
               let audioSession = AVAudioSession.sharedInstance()
                if audioSession.outputVolume > audioLevel || audioSession.outputVolume > 0.999 {
                    print("Volume Up")
                    audioLevel = audioSession.outputVolume
                    mButtonState = 0;
                }
                if audioSession.outputVolume < audioLevel || audioSession.outputVolume < 0.001 {
                    print("Volume Down")
                    audioLevel = audioSession.outputVolume
                    self.mButtonState = 2
                }
                if audioSession.outputVolume > 0.999 {
                    print("Volume Up")
                    mButtonState = 0;
                    audioLevel = 0.9375
                }
                        
                if audioSession.outputVolume < 0.001 {
                    print("Volume Down")
                    audioLevel = 0.0625
                    self.mButtonState = 2
                }
           }
       }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }
    
    func start()  {
//        self.skipSendMax = Int(delay.text!) ?? 0
//        sliderValue.isEnabled = false
//        calibrateButton.isEnabled = false
        DispatchQueue.main.async {
            self.calculateQuaternionValues()
        }
//        handleGyroscope()
    }
    
    func stop() {
        streamStatus.text = "Click to Re-calibrate"
        calibrateButton.isEnabled = true
        sliderValue.isEnabled = true
//        motion.stopGyroUpdates()
        motion.stopDeviceMotionUpdates()
        
    }
    
    func send() {
        print("Send")
        var response = ""
//        let response = RemoteTunnel().sendArr(data: mSensorData)
        if server.url != "" && server.port != 0 {
            response = server.sendArr(data: mSensorData)
            if response.contains("contact") {
//                print("Inside response", response)
                if mVibrationStrength > 0 && mVibrationStrength < 4 {
                    HapticsManager.shared.vibrate(for: .warning)
                }
                else if mVibrationStrength > 4 && mVibrationStrength < 7 {
                    HapticsManager.shared.vibrate(for: .error)
                }
                else if mVibrationStrength > 7 && mVibrationStrength < 10 {
                    HapticsManager.shared.vibrate(for: .success)
                }
                else {
                    HapticsManager.shared.impactVibrate()
                }
            }
        }
        
//        print(response.elementsEqual("contact"))
        
    }
    
    func calculateQuaternionValues() {
        if motion.isDeviceMotionAvailable {
            let queue = OperationQueue.current
            motion.deviceMotionUpdateInterval = 0.1
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue!) { (motion, error) in
                guard let motion = motion else { return }

                let quat = motion.attitude.quaternion
                
                self.mSensorQuat = CMQauternionControl(x: quat.x, y: quat.y, z: quat.z, w: quat.w)
                
                if self.mCalibrated {
                    self.mQuat = self.mCalibrateQuat * self.mSensorQuat
                    if self.mFlipDown == 0 && abs(self.mQuat.x) > 0.92 {
                        self.mFlipDown = 1
                        self.streamStatus.text = "Click to Re-calibrate"
                        print("1: ",self.mFlipDown, self.mQuat.x * 10)
                    }
                    else if self.mFlipDown == 1 && abs(self.mQuat.x * 10) < 0.1 {
                        self.mFlipDown = 0
                        self.streamStatus.text = "Click to Re-calibrate"
                        print("0: ",self.mFlipDown, self.mQuat.x * 10)
                    }
                }
                else {
                    self.mQuat = self.mSensorQuat
                }

                self.wQuaternion.text = "w: \((self.mQuat.w).rounded(toPlaces: 3))"
                self.xQuaternion.text = "x: \((self.mQuat.x).rounded(toPlaces: 3))"
                self.yQuaternion.text = "y: \((self.mQuat.y).rounded(toPlaces: 3))"
                self.zQuaternion.text = "z: \((self.mQuat.z).rounded(toPlaces: 3))"
                
            if self.mTouchView.isOnTouch {
                self.mMotionStateY = self.mTouchView.motionY
                self.mMotionStateX = self.mTouchView.motionX * (-1)
                self.mSensorData = "\(self.mDeviceId), \(self.mButtonState), \(Double(self.mMotionStateY).rounded(toPlaces: 3)), \(Double(self.mMotionStateX).rounded(toPlaces: 3)), \(Double(self.mQuat.x).rounded(toPlaces: 3)), \(Double(self.mQuat.y).rounded(toPlaces: 3)), \(Double(self.mQuat.z).rounded(toPlaces: 3)), \(Double(self.mQuat.w).rounded(toPlaces: 3))"
                print(self.mSensorData)

                if self.skipSendMax < 1 {
                    self.send()
                    if self.mButtonState == 3 {
                        self.mButtonState = 0
                    }
                }
                else if self.curSkipSend == 0 {
                    self.send()
                    self.curSkipSend += 1
                    if self.mButtonState == 3 {
                        self.mButtonState = 0
                    }
                }
                else if self.curSkipSend >= self.skipSendMax {
                    self.curSkipSend = 0
                }
                else {
                    self.curSkipSend += 1
                }

                }
            }
        }
        return
    }
    
//    func handleGyroscope() {
//        motion.gyroUpdateInterval = 0.01
//        motion.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
////        print(data as Any)
//            if let trueData = data {
//                self.view.reloadInputViews()
//                let x = trueData.rotationRate.x
//                let y = trueData.rotationRate.y
//                let z = trueData.rotationRate.z
//
//                if self.motion.isDeviceMotionAvailable == true {
//
//                    self.motion.deviceMotionUpdateInterval = 0.1
//
//                    let queue = OperationQueue()
//                    self.motion.startDeviceMotionUpdates(to: queue, withHandler: { [weak self] (motion, error) -> Void in
//
//                        if let attitude = motion?.attitude {
//                            let pitch = abs(attitude.pitch * 180.0/Double.pi)
//                            let roll = attitude.roll * 180.0/Double.pi
//                            let yaw = attitude.yaw * 180.0/Double.pi
//
//                            let qw = cos(roll/2)*cos(pitch/2)*cos(yaw/2) + sin(roll/2)*sin(pitch/2)*sin(yaw/2)
//                            let qx = sin(roll/2)*cos(pitch/2)*cos(yaw/2) - cos(roll/2)*sin(pitch/2)*sin(yaw/2)
//                            let qy = cos(roll/2)*sin(pitch/2)*cos(yaw/2) + sin(roll/2)*cos(pitch/2)*sin(yaw/2)
//                            let qz = cos(roll/2)*cos(pitch/2)*sin(yaw/2) - sin(roll/2)*sin(pitch/2)*cos(yaw/2)
//
//                            self!.mSensorQuat = Quaternion(x: Float32(qx), y: Float32(qy), z: Float32(qz), w: Float32(qw))
//                            print("Pitch ",attitude.pitch * 180.0/Double.pi)
//                            print("Absolute Value Pitch ",abs(attitude.pitch * 180.0/Double.pi))
//                            print("Roll ",attitude.roll * 180.0/Double.pi)
//                            print("Yaw ",attitude.yaw * 180.0/Double.pi)
//                            self!.mSensorQuat = Quaternion(angle: Float32(pitch), axis: Vector3(x: Float32(x), y: Float32(y), z: Float32(z)))
//
//                            }
//                        })
//
//                    }
//                self.mSensorQuat = Quaternion(x: Float32(x), y: Float32(y), z: Float32(z), w: 1.0)
//                self.mSensorQuat = Quaternion(angle: 90.0, axis: Vector3(x: Float32(x), y: Float32(y), z: Float32(z)))
//
//                if self.mCalibrated {
//                    self.mQuat = self.mCalibrateQuat * self.mSensorQuat
//                    if self.mFlipDown == 0 && abs(self.mQuat.x) > 0.92 {
//                        self.mFlipDown = 1
//                    }
//                    else if self.mFlipDown == 1 && abs(self.mQuat.x) < 0.1 {
//                        self.mFlipDown = 0
//                    }
//                }
//
//                else {
//                    self.mQuat = self.mSensorQuat
//                }
//
//                self.wQuaternion.text = "w: \(Double(self.mQuat.w).rounded(toPlaces: 3))"
//                self.xQuaternion.text = "x: \(Double(self.mQuat.x).rounded(toPlaces: 3))"
//                self.yQuaternion.text = "y: \(Double(self.mQuat.y).rounded(toPlaces: 3))"
//                self.zQuaternion.text = "z: \(Double(self.mQuat.z).rounded(toPlaces: 3))"
//            }
            
//            if self.mTouchView.isOnTouch {
//                self.mMotionStateY = self.mTouchView.motionY
//                self.mMotionStateX = self.mTouchView.motionY
//                self.mSensorData = "\(self.mDeviceId) \(self.mButtonState) \(Double(self.mMotionStateY).rounded(toPlaces: 3)) \(Double(self.mMotionStateX).rounded(toPlaces: 3)) \(Double(self.mQuat.x).rounded(toPlaces: 3)) \(Double(self.mQuat.y).rounded(toPlaces: 3)) \(Double(self.mQuat.z).rounded(toPlaces: 3)) \(Double(self.mQuat.w).rounded(toPlaces: 3))"
//                print(self.mSensorData)
//
//                if self.skipSendMax < 1 {
//                    self.send()
//                    if self.mButtonState == 3 {
//                        self.mButtonState = 0
//                    }
//                }
//                else if self.curSkipSend == 0 {
//                    self.send()
//                    self.curSkipSend += 1
//                    if self.mButtonState == 3 {
//                        self.mButtonState = 0
//                    }
//                }
//                else if self.curSkipSend >= self.skipSendMax {
//                    self.curSkipSend = 0
//                }
//                else {
//                    self.curSkipSend += 1
//                }
//
//            }
//        }
//        return
//    }



}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

