//
//  TitleCollectionViewCell.swift
//  TVHeadend Client
//
//  Created by Kin Wai Koo on 26/1/19.
//

import UIKit

class TitleCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var titleLabel : UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func commonInit() {
        // Initialization code
        self.layoutIfNeeded()
        self.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (self.isFocused) {
            self.titleLabel.textColor = UIColor.black
        } else {
            self.titleLabel.textColor = UIColor.lightGray
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
