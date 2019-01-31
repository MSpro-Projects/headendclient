//
//  EpisodeViewController.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 2019-01-01.
//  Parts of this code were copied from http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/.
//

import Foundation
import UIKit

// todo: implement delete

class EpisodeViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, VideoDetailsDelegate, ChannelIconDisplay {
    @IBOutlet weak var navBar : UINavigationBar!
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var timeLabel : UILabel!
    @IBOutlet weak var descriptionTextView : UITextView!
    @IBOutlet weak var channelImageView : UIImageView!
    
    let reuseIdentifierTitle = "EpisodeCollectionViewCell"
    var tvh: TvhServer?
    var titleName: String?
    var episodes: [VideoMetadata]?
    
    override func viewDidLoad() {
        guard let title = titleName else {
            return
        }
        navBar.topItem?.title = title
    }
    
    func showVideoDetails(data: VideoMetadata) {
        var timeText = "Recorded "
        let tzOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        timeText.append(DateFormatter.localizedString(from: data.getStartTimeAsDate() + tzOffset, dateStyle: .short, timeStyle: .short))
        timeText.append(" - ")
        timeText.append(DateFormatter.localizedString(from: data.getStopTimeAsDate() + tzOffset, dateStyle: .none, timeStyle: .short))
        self.timeLabel.text = timeText
        
        var description = ""
        if let tmpDesc = data.description {
            description = tmpDesc
        }
        descriptionTextView.text = description
        
        tvh?.getChannelIcon(video: data, delegate: self)
    }
    
    func showChannelIcon(data: Data) {
        self.channelImageView.image = UIImage(data: data)
    }
    
    @objc func handleGesture(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "play", sender: self)
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        // todo: process delete here
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "play" { return }
        guard let tvh = self.tvh, let focusedCell = UIScreen.main.focusedView as? EpisodeCollectionViewCell, let meta = focusedCell.videoMetadata, let dest = segue.destination as? VideoPlayerViewController else { return }
        dest.tvh = tvh
        dest.videoMetadata = meta
    }
    
    // Collection View Methods
    //
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 50.0, bottom: 0.0, right: 50.0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == self.collectionView) {
            if let episodes = self.episodes {
                return episodes.count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let episodes = self.episodes else {
            return UICollectionViewCell()
        }
        if (collectionView == self.collectionView) {
            let cell : EpisodeCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifierTitle, for: indexPath) as! EpisodeCollectionViewCell
            cell.setState(delegate: self, metadata: episodes[indexPath.row])
            
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleGesture(_:)))
            recognizer.allowedPressTypes = [NSNumber(integerLiteral: UIPress.PressType.playPause.rawValue), NSNumber(integerLiteral: UIPress.PressType.select.rawValue)]
            cell.addGestureRecognizer(recognizer)
            
            let longpress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
            cell.addGestureRecognizer(longpress)
            
            return cell
        }
        return UICollectionViewCell()
    }
}
