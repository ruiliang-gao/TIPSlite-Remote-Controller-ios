//
//  CanvasViewController.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/15/21.
//

import UIKit

class CanvasViewController: UIViewController {
    
    let canvas = Canvas()
    
    override func loadView() {
        self.view = canvas
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canvas.backgroundColor = .white
    }

}
