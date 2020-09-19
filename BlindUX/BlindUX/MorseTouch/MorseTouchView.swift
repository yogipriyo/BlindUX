//
//  MorseTouchView.swift
//  BlindUX
//
//  Created by Yogi Priyo on 20/09/20.
//

import Foundation
import UIKit
import AVFoundation

enum MorseCodeItem {
    case dot
    case dash
}

enum TranslationType {
    case alphabet
    case numeric
    case specialChar
}

enum ActionType {
    case upCase
    case deleteCode
    case inputCode
    case nothing
}

protocol MorseTouchViewDelegate: class {
    func displayMorseTouch()
    func sendTranslation(translatedText: String, targetTextField: UITextField)
    func sendForm()
    func removeMorseTouch(targetView: UIView, tagNumber: Int)
    func backToPreviousPage()
}

final class MorseTouchView: UIView {
    
    // MARK: - Properties
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var codeInputView: UIView!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var individualResultLabel: UILabel!
    @IBOutlet weak var combinedResultLabel: UILabel!
    
    weak var delegate: MorseTouchViewDelegate?
    var welcomeText: String?
    var targetFields: [FormTextField] = []
    var targetButtons: [FormButton] = []
    var activeTargetFieldIndex: Int = 0
    var activeCodeItem: [MorseCodeItem] = []
    var displayResultView: Bool = true
    var translatedItems: [String] = []
    var longPressMenuActive: Bool = false
    var submitPromptActive: Bool = false
    static let synthesizer = AVSpeechSynthesizer()
    let locale = NSLocale.current.languageCode
    let alphabetMorseCodes: [[MorseCodeItem]:String] = [
        [.dot, .dash]: "a", [.dash, .dot, .dot, .dot]: "b", [.dash, .dot, .dash, .dot]: "c",
        [.dash, .dot, .dot]: "d", [.dot]: "e", [.dot, .dot, .dash, .dot]: "f",
        [.dash, .dash, .dot]: "g", [.dot, .dot, .dot, .dot]: "h", [.dot, .dot]: "i",
        [.dot, .dash, .dash, .dash]: "j", [.dash, .dot, .dash]: "k", [.dot, .dash, .dot, .dot]: "l",
        [.dash, .dash]: "m", [.dash, .dot]: "n", [.dash, .dash, .dash]: "o",
        [.dot, .dash, .dash, .dot]: "p", [.dash, .dash, .dot, .dash]: "q", [.dot, .dash, .dot]: "r",
        [.dot, .dot, .dot]: "s", [.dash]: "t", [.dot, .dot, .dash]: "u",
        [.dot, .dot, .dot, .dash]: "v", [.dot, .dash, .dash]: "w", [.dash, .dot, .dot, .dash]: "x",
        [.dash, .dot, .dash, .dash]: "y", [.dash, .dash, .dot, .dot]: "z"
    ]
    let numericMorseCodes: [[MorseCodeItem]:Int] = [
        [.dot, .dash, .dash, .dash, .dash]: 1, [.dot, .dot, .dash, .dash, .dash]: 2,
        [.dot, .dot, .dot, .dash, .dash]: 3, [.dot, .dot, .dot, .dot, .dash]: 4,
        [.dot, .dot, .dot, .dot, .dot]: 5, [.dash, .dot, .dot, .dot, .dot]: 6,
        [.dash, .dash, .dot, .dot, .dot]: 7, [.dash, .dash, .dash, .dot, .dot]: 8,
        [.dash, .dash, .dash, .dash, .dot]: 9, [.dash, .dash, .dash, .dash, .dash]: 0
    ]
    let specialChars: [[MorseCodeItem]:String] = [
        [.dot, .dash, .dash, .dot, .dash, .dot]: "@", [.dot, .dash, .dot, .dash, .dot, .dash]: ".",
        [.dot, .dot, .dash, .dash, .dot, .dot]: "?", [.dot, .dot, .dash, .dash, .dot, .dash]: "_",
    ]
    let unrecognizedCode: String = NSLocalizedString("unrecognized_code", comment: "")
    
    // MARK: - Initializers
    
    required init(targetFields: [FormTextField] = [], targetButtons: [FormButton] = [], welcomeText: String? = nil ) {
        super.init(frame: .zero)
        self.welcomeText = welcomeText
        if !targetFields.isEmpty { self.targetFields = targetFields }
        if !targetButtons.isEmpty { self.targetButtons = targetButtons }
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - Functions
    
    func commonInit(){
        self.loadCustomNib()
        self.setupGestures()
        self.setupWelcomeSpeech()
    }
    
    func loadCustomNib() {
        Bundle.main.loadNibNamed("MorseTouchView", owner: self, options: nil)
        addSubview(self.contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func setupWelcomeSpeech() {
        if let welcomeText = self.welcomeText { self.text2speech(keyword: welcomeText) }
        if !self.targetFields.isEmpty {
            self.text2speech(keyword: "\(NSLocalizedString("current_text_field_prefix", comment: "")) \(self.targetFields[0].name)")
        }
    }
    
    func setupGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            rightSwipe.direction = .right
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            downSwipe.direction = .down
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            upSwipe.direction = .up
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            singleTap.numberOfTapsRequired = 1
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
            doubleTap.numberOfTapsRequired = 2
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        
        let gestureArray = [leftSwipe, rightSwipe, downSwipe, upSwipe, singleTap, doubleTap, longPress]
        for gestureItem in gestureArray {
            self.codeInputView.addGestureRecognizer(gestureItem)
        }
        
        singleTap.require(toFail: doubleTap)
    }
    
    @objc func doubleTapped() {
        //Log.debug(title: "double tap")
        if !self.translatedItems.isEmpty {
            var translatedText: String = ""
            for item in self.translatedItems {
                translatedText += item
            }
            self.text2speech(keyword: translatedText)
        } else {
            self.text2speech(keyword: NSLocalizedString("empty_translated_text", comment: ""))
        }
        self.activeCodeItem.removeAll()
    }
    
    @objc func handleLongPress() {
        if !self.longPressMenuActive {
            //Log.debug(title: "long press")
            self.longPressMenuActive = true
            self.text2speech(keyword: NSLocalizedString("open_central_menu", comment: ""))
        }
    }

    @objc func handleTap(_ sender:UITapGestureRecognizer) {
        //Log.debug(title: "single tap")
        if self.longPressMenuActive {
            self.longPressMenuActive = false
            self.text2speech(keyword: NSLocalizedString("close_central_menu", comment: ""))
        } else {
            self.composeMorseCode(morseCodeItem: .dot)
            self.text2speech(keyword: NSLocalizedString("morse_code_dot", comment: ""))
        }
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        switch sender.direction {
        case .left:
            //Log.debug(title: "swipe left")
            if self.submitPromptActive {
                self.text2speech(keyword: NSLocalizedString("stay_on_current_page", comment: ""))
                self.submitPromptActive = false
            } else if self.longPressMenuActive {
                self.text2speech(keyword: NSLocalizedString("back_to_previous_page", comment: ""))
                self.longPressMenuActive = false
                self.delegate?.backToPreviousPage()
            } else {
                self.deletePreviousItems()
            }
        case .right:
            //Log.debug(title: "swipe right")
            if self.submitPromptActive {
                self.text2speech(keyword: NSLocalizedString("submit_form", comment: ""))
                self.delegate?.sendForm()
                self.submitPromptActive = false
            } else {
                self.composeMorseCode(morseCodeItem: .dash)
                self.text2speech(keyword: NSLocalizedString("morse_code_dash", comment: ""))
            }
        case .down:
            //Log.debug(title: "swipe down")
            if self.longPressMenuActive {
                self.longPressMenuActive = false
                self.moveToNextField()
            } else {
                self.individualResultLabel.text = "\(NSLocalizedString("result_text", comment: "")): \(self.compileMorseCode())"
            }
        default:
            //Log.debug(title: "swipe up")
            if self.longPressMenuActive {
                self.longPressMenuActive = false
                self.moveToPreviousField()
            }
        }
    }
    
    fileprivate func submitFormPrompt() {
        self.submitPromptActive = true
        self.text2speech(keyword: NSLocalizedString("submit_form_prompt_question", comment: ""))
    }
    
    fileprivate func moveToNextField() {
        switch self.targetFields.count {
        case 1:
            self.text2speech(keyword: NSLocalizedString("only_has_single_field", comment: ""))
        case 1...:
            if (self.activeTargetFieldIndex+1) == self.targetFields.count {
                self.text2speech(keyword: NSLocalizedString("last_field", comment: ""))
                self.submitFormPrompt()
            } else {
                self.activeTargetFieldIndex += 1
                self.text2speech(keyword: "\(NSLocalizedString("move_to_the_next_field", comment: "")), \(self.targetFields[self.activeTargetFieldIndex].name)")
                self.translatedItems.removeAll()
            }
        default:
            self.text2speech(keyword: NSLocalizedString("has_no_field", comment: ""))
        }
    }
    
    fileprivate func moveToPreviousField() {
        switch self.targetFields.count {
        case 1:
            self.text2speech(keyword: NSLocalizedString("only_has_single_field", comment: ""))
        case 1...:
            if self.activeTargetFieldIndex == 0 {
                self.text2speech(keyword: NSLocalizedString("first_field", comment: ""))
            } else {
                self.activeTargetFieldIndex -= 1
                self.text2speech(keyword: "\(NSLocalizedString("move_to_the_next_field", comment: "")), \(self.targetFields[self.activeTargetFieldIndex].name)")
                self.translatedItems.removeAll()
            }
        default:
            self.text2speech(keyword: NSLocalizedString("has_no_field", comment: ""))
        }
    }
    
    fileprivate func composeMorseCode(morseCodeItem: MorseCodeItem) {
        self.activeCodeItem.append(morseCodeItem)
    }
    
    fileprivate func compileMorseCode() -> String {
        var finalResult: String = self.unrecognizedCode
        
        if let stringResult = self.checkForAlphabet(morseCode: self.activeCodeItem) {
            finalResult = stringResult
        } else if let numericResult = self.checkForNumeric(morseCode: self.activeCodeItem) {
            finalResult = String(numericResult)
        } else if let specialCharResult = self.checkForSpecialChar(morseCode: self.activeCodeItem) {
            finalResult = specialCharResult
        }

        if finalResult != self.unrecognizedCode {
            self.translatedItems.append(finalResult)
            self.updateTranslatedText()
        }
        self.text2speech(keyword: finalResult)
        self.activeCodeItem.removeAll()
        return finalResult
    }
    
    fileprivate func text2speech(keyword: String, actionType: ActionType = .nothing) {
        let utterance = AVSpeechUtterance(string: actionType == .deleteCode ? "\(NSLocalizedString("delete", comment: "")) \(keyword)" : keyword)
        utterance.voice = AVSpeechSynthesisVoice(language: locale ?? "id")

        MorseTouchView.synthesizer.speak(utterance)
    }
    
    fileprivate func deletePreviousItems() {
        if let removedElement = self.translatedItems.popLast() {
            self.updateTranslatedText()
            self.text2speech(keyword: removedElement, actionType: .deleteCode)
            self.individualResultLabel.text = "\(NSLocalizedString("result_text", comment: "")): _"
        }
    }
    
    fileprivate func updateTranslatedText() {
        var translatedText: String = ""
        for item in self.translatedItems {
            translatedText += item
        }
        self.combinedResultLabel.text = "\(NSLocalizedString("combined_result_text", comment: "")): \(translatedText)"
        
        if !self.targetFields.isEmpty {
            self.delegate?.sendTranslation(translatedText: translatedText, targetTextField: self.targetFields[self.activeTargetFieldIndex].target)
        }
    }
    
    fileprivate func checkForAlphabet(morseCode: [MorseCodeItem]) -> String? {
        let dictResult = self.alphabetMorseCodes.filter { $0.key == morseCode }
        return dictResult[morseCode]
    }
    
    fileprivate func checkForNumeric(morseCode: [MorseCodeItem]) -> Int? {
        let dictResult = self.numericMorseCodes.filter { $0.key == morseCode }
        return dictResult[morseCode]
    }
    
    fileprivate func checkForSpecialChar(morseCode: [MorseCodeItem]) -> String? {
        let dictResult = self.specialChars.filter { $0.key == morseCode }
        return dictResult[morseCode]
    }
    
    fileprivate func displayResult(result: String) {
        self.resultView.isHidden = !self.displayResultView
        self.individualResultLabel.text = "\(NSLocalizedString("result_text", comment: "")): \(result)"
    }
}

extension MorseTouchViewDelegate {
    func sendTranslation(translatedText: String, targetTextField: UITextField) { }
    func sendForm() { }
    func backToPreviousPage() { }
}
