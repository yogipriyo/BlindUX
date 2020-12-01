//
//  HomepageMenuCollectionViewCell.swift
//  BlindUXExamples
//
//  Created by Yogi Priyo on 30/11/20.
//

import UIKit

class HomepageMenuCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var menuTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupContent(menuIndex: Int) {
        self.menuTitleLabel.text = "Menu \(menuIndex)"
    }

}
