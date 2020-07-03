//
//  AEPageThreeController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 7/2/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class AEPageThreeController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func presentGetPassword() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetPasswordController") as! GetPasswordController
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
        
    }

    @IBAction func nextButtonTapped(_ sender: Any) {
        presentGetPassword()
    }
}
