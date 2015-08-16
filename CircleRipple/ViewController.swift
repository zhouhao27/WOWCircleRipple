//
//  ViewController.swift
//  CircleRipple
//
//  Created by Zhou Hao on 15/08/15.
//  Copyright © 2015年 Zeus. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var button: WOWCircleRippleButton!
    
    @IBOutlet weak var loginButton: WOWCircleRippleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func onClick(sender: AnyObject) {
        
        button.startAction()
        GCD.delay(2) { () -> () in
            self.button.stopAction(self.view, animated: true)
        }
    }

    @IBAction func onLogin(sender: AnyObject) {
        
        loginButton.startAction()
        GCD.delay(3) { () -> () in
            self.loginButton.stopAction(true)
        }
    }
}

