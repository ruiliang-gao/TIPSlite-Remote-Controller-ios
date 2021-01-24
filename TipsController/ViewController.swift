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
    private var mSensorQuat = Quaternion()
    private var mQuat = Quaternion()
    private var mCalibrateQuat = Quaternion()
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
//                   print("Hello")
                   audioLevel = audioSession.outputVolume
//                    sliderValue.value += 1
               }
               if audioSession.outputVolume < audioLevel {
//                   print("GoodBye")
                   audioLevel = audioSession.outputVolume
                   self.mButtonState = 2
//                    sliderValue.value -= 1
               }
                if audioSession.outputVolume > 9.99 {
                (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(9.375, animated: false)
                    audioLevel = 9.375
               }
               
               if audioSession.outputVolume < 0.1 {
                   (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(0.625, animated: false)
                   audioLevel = 0.625
               }
           }
       }
    
    func start()  {
        handleGyroscope()
    }
    
    func stop() {
        motion.stopGyroUpdates()
    }
    
    func send() {
        print("Send")
        let response = RemoteTunnel().sendArr(data: mSensorData)
        print(response)
    }
    
    func handleGyroscope() {
        motion.gyroUpdateInterval = 0.1
        motion.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
//        print(data as Any)
            if let trueData = data {
                self.view.reloadInputViews()
                let x = trueData.rotationRate.x
                let y = trueData.rotationRate.y
                let z = trueData.rotationRate.z
                
                
                self.mSensorQuat = Quaternion(x: Float32(x), y: Float32(y), z: Float32(z), w: 1.0)
                
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
                
                self.wQuaternion.text = "w: \(Double(self.mQuat.w).rounded(toPlaces: 3))"
                self.xQuaternion.text = "x: \(Double(self.mQuat.x).rounded(toPlaces: 3))"
                self.yQuaternion.text = "y: \(Double(self.mQuat.y).rounded(toPlaces: 3))"
                self.zQuaternion.text = "z: \(Double(self.mQuat.z).rounded(toPlaces: 3))"
            }
            
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
        return
    }


}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

