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
    

    @IBOutlet weak var delay: UITextField!
    
    @IBAction func delayEnter(_ sender: Any) {
        skipSendMax = Int(delay.text!) ?? 0
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
        let sliderVal = sliderValue.value
        if sliderVal > 0 && sliderVal < 4 {
            HapticsManager.shared.vibrate(for: .warning)
        }
        else if sliderVal > 4 && sliderVal < 7 {
            HapticsManager.shared.vibrate(for: .error)
        }
        else if sliderVal > 7 && sliderVal < 10 {
            HapticsManager.shared.vibrate(for: .success)
        }
        else {
            HapticsManager.shared.impactVibrate()
        }
    }
    
    
    @IBOutlet weak var joinButton: UIButton!
    
    @IBAction func joinServer(_ sender: Any) {
        let response = RemoteTunnel()
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
        streamStatus.text = "Calibrated Flip to start…"
        calibrateButton.setTitle("Recalibrate", for: .normal)
    }
    
    @IBOutlet weak var mTouchView: DrawView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        start()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
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
               if audioSession.outputVolume > audioLevel {
                   print("Hello")
                   audioLevel = audioSession.outputVolume
//                    sliderValue.value += 1
               }
            if audioSession.outputVolume < audioLevel {
                   print("GoodBye")
                   audioLevel = audioSession.outputVolume
                   self.mButtonState = 2
//                    sliderValue.value -= 1
               }
//                if audioSession.outputVolume > 9.99 {
//                    print("GoodBye 1")
//                (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(9.375, animated: false)
//                    audioLevel = 9.375
//               }
//
//               if audioSession.outputVolume < 0.1 {
//                print("GoodBye 2")
//                   (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(0.625, animated: false)
//                   audioLevel = 0.625
//               }
           }
       }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }
    
    func start()  {
//        self.skipSendMax = Int(delay.text!) ?? 0
        calculateQuaternionValues()
//        handleGyroscope()
    }
    
    func stop() {
        streamStatus.text = "Click to Re-calibrate"
        calibrateButton.isEnabled = true
//        motion.stopGyroUpdates()
        motion.stopDeviceMotionUpdates()
        
    }
    
    func send() {
        print("Send")
        let response = RemoteTunnel().sendArr(data: mSensorData)
        print(response)
    }
    
    func calculateQuaternionValues() {
        if motion.isDeviceMotionAvailable {
            let queue = OperationQueue.current
            motion.deviceMotionUpdateInterval = 1 / 60
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue!) { (motion, error) in
                guard let motion = motion else { return }

                let quat = motion.attitude.quaternion
                
                self.mSensorQuat = CMQauternionControl(x: quat.x, y: quat.y, z: quat.z, w: quat.w)
                
                if self.mCalibrated {
                    self.mQuat = self.mCalibrateQuat * self.mSensorQuat
                    if self.mFlipDown == 0 && abs(self.mQuat.x) > 0.92 {
                        self.mFlipDown = 1
                    }
                    else if self.mFlipDown == 1 && abs(self.mQuat.x) < 0.1 {
                        self.mFlipDown = 0
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
                self.mMotionStateX = self.mTouchView.motionY
                self.mSensorData = "\(self.mDeviceId) \(self.mButtonState) \(Double(self.mMotionStateY).rounded(toPlaces: 3)) \(Double(self.mMotionStateX).rounded(toPlaces: 3)) \(Double(self.mQuat.x).rounded(toPlaces: 3)) \(Double(self.mQuat.y).rounded(toPlaces: 3)) \(Double(self.mQuat.z).rounded(toPlaces: 3)) \(Double(self.mQuat.w).rounded(toPlaces: 3))"
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

