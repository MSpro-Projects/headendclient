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

class EpisodeViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, VideoDetailsDelegate, ChannelIconDisplay, DeleteRecordingDelegate {
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
        loadEpisodes()
    }
    
    func setState(tvhserver: TvhServer, title: String) {
        tvh = tvhserver
        titleName = title
    }
    
    func loadEpisodes() {
        guard let title = self.titleName, let tvh = self.tvh else { return }
        episodes = tvh.getRecordedPrograms(title: title)
        collectionView.reloadData()
    }
    
    func showVideoDetails(data: VideoMetadata) {
        var timeText = "Recorded "
        let tzOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        timeText.append(DateFormatter.localizedString(from: data.getStartTimeAsDate() + tzOffset, dateStyle: .short, timeStyle: .short))
        timeText.append(" - ")
        timeText.append(DateFormatter.localizedString(from: data.getStopTimeAsDate() + tzOffset, dateStyle: .none, timeStyle: .short))
        self.timeLabel.text = timeText
        
        descriptionTextView.text = data.description ?? ""
        
        tvh?.getChannelIcon(video: data, delegate: self)
    }
    
    func showChannelIcon(data: Data) {
        self.channelImageView.image = UIImage(data: data)
    }
    
    func deleteRecordingSuccessful(metadata: VideoMetadata) {
        // todo: update cached data appropriately
        // todo: if the number of episodes == 0, then we need to return to the title view
        print("delete recording successful")
    }
    
    @objc func handleGesture(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "play", sender: self)
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        performSegue(withIdentifier: "delete", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "play" {
            guard let tvh = self.tvh, let focusedCell = UIScreen.main.focusedView as? EpisodeCollectionViewCell, let meta = focusedCell.videoMetadata, let dest = segue.destination as? VideoPlayerViewController else { return }
            dest.setState(tvhserver: tvh, metadata: meta)
            return
        }
        if segue.identifier == "delete" {
            guard let tvh = self.tvh, let focusedCell = UIScreen.main.focusedView as? EpisodeCollectionViewCell, let meta = focusedCell.videoMetadata, let dest = segue.destination as? DeleteRecordingViewController else { return }
            dest.setState(deleteDelegate: self, tvhserver: tvh, videometadata: meta)
            return
        }
        
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
            
            let existingGestureRecognizers =  cell.gestureRecognizers
            if existingGestureRecognizers == nil || existingGestureRecognizers?.count == 0 {
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleGesture(_:)))
                recognizer.allowedPressTypes = [NSNumber(integerLiteral: UIPress.PressType.playPause.rawValue), NSNumber(integerLiteral: UIPress.PressType.select.rawValue)]
                cell.addGestureRecognizer(recognizer)
                
                let longpress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
                cell.addGestureRecognizer(longpress)
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
}
