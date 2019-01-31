//
//  EpisodeCollectionViewCell.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 2019-01-01.
//  Parts of this code were copied from http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/.
//

import UIKit

class EpisodeCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var subtitleLabel : UILabel!
    var videoMetadata : VideoMetadata?
    private var detailsDelegate : VideoDetailsDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setState(delegate: VideoDetailsDelegate, metadata: VideoMetadata) {
        detailsDelegate = delegate
        videoMetadata = metadata
        subtitleLabel.text = generateSubtitleText()
    }
    
    func generateSubtitleText() -> String {
        guard let v = self.videoMetadata else { return "Error" }
        if let subtitle = v.subtitle, subtitle.count > 0 {
            return subtitle
        }
        
        let tzOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return DateFormatter.localizedString(from: v.getStartTimeAsDate() + tzOffset, dateStyle: .medium, timeStyle: .short)
    }
    
    private func commonInit() {
        // Initialization code
        self.layoutIfNeeded()
        self.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (self.isFocused) {
            self.subtitleLabel.textColor = UIColor.black
            if let delegate = self.detailsDelegate, let details = self.videoMetadata {
                delegate.showVideoDetails(data: details)
            }
        } else {
            self.subtitleLabel.textColor = UIColor.lightGray
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
