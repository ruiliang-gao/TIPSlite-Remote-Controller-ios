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
    var status: String = ""
    

    @IBOutlet weak var delay: UITextField!
    
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
        print(sliderVal)
        HapticsManager.shared.impactVibrate()
    }
    
    
    @IBOutlet weak var joinButton: UIButton!
    
    @IBAction func joinServer(_ sender: Any) {
        let response = RemoteTunnel()
        
        joinButton.titleLabel?.text = "Connected"
        
    }
    
    
    @IBAction func calibrateAction(_ sender: Any) {
      
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        myGyroscope()
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
                    sliderValue.value += 1
                    HapticsManager.shared.impactVibrate()
               }
               if audioSession.outputVolume < audioLevel {
                   print("GoodBye")
                   audioLevel = audioSession.outputVolume
                    sliderValue.value -= 1
                    HapticsManager.shared.impactVibrate()
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
    
    func myGyroscope() {
        motion.gyroUpdateInterval = 0.1
        motion.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
//        print(data as Any)
            if let trueData = data {
                self.view.reloadInputViews()
                let x = trueData.rotationRate.x
                let y = trueData.rotationRate.y
                let z = trueData.rotationRate.z
                
                
                let rotQuat = Quaternion(x: Float32(x), y: Float32(y), z: Float32(z), w: 1.0)
                
                self.wQuaternion.text = "w: \(Double(rotQuat.w).rounded(toPlaces: 3))"
                self.xQuaternion.text = "x: \(Double(rotQuat.x).rounded(toPlaces: 3))"
                self.yQuaternion.text = "y: \(Double(rotQuat.y).rounded(toPlaces: 3))"
                self.zQuaternion.text = "z: \(Double(rotQuat.z).rounded(toPlaces: 3))"
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

