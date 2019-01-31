//
//  AudioCollectionViewCell.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 2019-01-01.
//  Parts of this code were copied from http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/.
//

import UIKit

class SettingsCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var selectedLabel : UILabel!
    @IBOutlet weak var descriptionLabel : UILabel!
    
    var isAudioTrack : Bool = false
    var trackID : Int32 = 0
    
    func setState(isaudio: Bool, selected: Bool, trackid: Int32, description: String) {
        self.isAudioTrack = isaudio
        self.trackID = trackid
        var selectedText = ""
        if selected { selectedText = "\u{2713}"}
        selectedLabel.text = selectedText
        descriptionLabel.text = description
    }
    
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
        var color = UIColor.lightGray
        if self.isFocused { color = UIColor.black }
        
        self.selectedLabel.textColor = color
        self.descriptionLabel.textColor = color
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
