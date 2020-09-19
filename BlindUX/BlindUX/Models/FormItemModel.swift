//
//  FormItemModel.swift
//  BlindUX
//
//  Created by Yogi Priyo on 20/09/20.
//

import Foundation
import UIKit

struct FormTextField {
    let name: String
    let description: String? = nil
    let target: UITextField
}

struct FormButton {
    let name: String
    let description: String? = nil
    let target: UIButton
}
