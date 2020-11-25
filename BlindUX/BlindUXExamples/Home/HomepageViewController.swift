//
//  HomepageViewController.swift
//  BlindUXExamples
//
//  Created by Yogi Priyo on 17/11/20.
//

import UIKit

final class HomepageViewController: UIViewController, MorseTouchViewDelegate {
    
    // MARK: - Properties
    var isLoggedIn: Bool = false
    let morseCodeViewTag: Int = 100
    var topMenu: [String] = ["Login", "Register", "Menu A", "Menu B", "Menu C"]
    
    // MARK: - Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.displayMorseTouch()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeMorseTouch(targetView: self.view, tagNumber: self.morseCodeViewTag)
    }

    // MARK: - Private Functions
    
    fileprivate func setupNavbar() {
        self.navigationItem.title = "Homepage"
    }

    // MARK: - MorseTouchViewDelegate
    
    func readTheMenu() {
//        if self.isLoggedIn { self.topMenu.remove(at: 0) }
        
    }
    
    func displayMorseTouch() {
        let targetViewFrame: CGRect = self.view.frame
        let morseTouchView: MorseTouchView = MorseTouchView(welcomeText: NSLocalizedString("homepage_welcome_text", tableName: "LocalizableExample", bundle: .main, value: "Invalid key", comment: ""))
        morseTouchView.delegate = self
        morseTouchView.tag = self.morseCodeViewTag
        morseTouchView.frame = CGRect(x: targetViewFrame.origin.x, y: targetViewFrame.origin.y, width: targetViewFrame.width, height: targetViewFrame.height)
        self.view.addSubview(morseTouchView)
    }
    
    func removeMorseTouch(targetView: UIView, tagNumber: Int) {
        if let viewWithTag = targetView.viewWithTag(tagNumber) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    func backToPreviousPage() {
        self.navigationController?.popViewController(animated: true)
    }
}
