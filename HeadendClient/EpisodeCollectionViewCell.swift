//
//  EpisodeCollectionViewCell.swift
//  TVHeadend Client
//
//  Created by Kin Wai Koo on 2019-01-01.
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
    
    func setVideoMetadata(metaData: VideoMetadata) {
        self.videoMetadata = metaData
        self.subtitleLabel.text = generateSubtitleText()
    }
    
    func setVideoDetailsDelegate(delegate: VideoDetailsDelegate) {
        self.detailsDelegate = delegate
    }
    
    func generateSubtitleText() -> String {
        guard let v = self.videoMetadata else { return "Error" }
        if let subtitle = v.subtitle, subtitle.count > 0 {
            return subtitle
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'hh:mm a"
        let tzOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return dateFormatter.string(from: v.getStartTimeAsDate() + tzOffset)
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
