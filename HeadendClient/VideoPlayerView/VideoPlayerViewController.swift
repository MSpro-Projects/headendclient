//
//  VideoPlayerViewController.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 28/1/19.
//  Parts of this code were copied from http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/.
//


import UIKit
import GameController

struct TrackInfo {
    let trackid: Int32
    let description: String
}

class VideoPlayerViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, VLCMediaPlayerDelegate {
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var audioCollectionView: UICollectionView!
    @IBOutlet weak var subtitlesCollectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    let reuseIdentifierTitle = "SettingsCollectionViewCell"
    let jumpForwardSeconds: Int32 = 20
    let jumpBackwardSeconds: Int32 = 10
    
    var player: VLCMediaPlayer?
    var tvh: TvhServer?
    var videoMetadata: VideoMetadata?
    var audioTracks: [TrackInfo] = []
    var subtitleTracks: [TrackInfo] = []
    var selectedAudioTrack: Int32 = 0
    var selectedSubtitleTrack: Int32 = 0
    var shouldUpdateTime: Bool = false  // strange things happen with the position if we update the time while animating
    var panOriginPosition: Float = 0
    var fastForwardRate = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsView.layer.zPosition = 5
        timeView.layer.zPosition = 4
        
        
        addSwipeGestureRecognizer(toview: movieView, direction: .left, selector: #selector(self.handleVideoSwipeLeft(_:)))
        addSwipeGestureRecognizer(toview: movieView, direction: .right, selector: #selector(self.handleVideoSwipeRight(_:)))
        addSwipeGestureRecognizer(toview: movieView, direction: .down, selector: #selector(self.handleVideoSwipeDown(_:)))
        
        
        addTapGestureRecognizer(toview: movieView, button: .select, selector: #selector(self.handleMainTapSelect(_:)))
        addTapGestureRecognizer(toview: movieView, button: .playPause, selector: #selector(self.handleTapPlay(_:)))
        
        addTapGestureRecognizer(toview: settingsView, button: .select, selector: #selector(self.handleSettingsTapSelect(_:)))
        addTapGestureRecognizer(toview: settingsView, button: .menu, selector: #selector(self.handleSettingsTapMenu(_:)))
        addTapGestureRecognizer(toview: settingsView, button: .playPause, selector: #selector(self.handleTapPlay(_:)))
        
        addTapGestureRecognizer(toview: timeView, button: .menu, selector: #selector(self.handleTimeTapMenu(_:)))
        addTapGestureRecognizer(toview: timeView, button: .playPause, selector: #selector(self.handleTapPlay(_:)))
        addPanGestureRecognizer(toview: timeView, selector: #selector(self.handleTimePan(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 1.0, animations: { self.movieView.alpha = 1.0 }, completion: { _ in self.completeInitialization() })
    }
    
    override weak var preferredFocusedView: UIView? {
        if !settingsView.isHidden {
            return settingsView
        }
        if !timeView.isHidden {
            return timeView
        }
        return movieView
    }
    
    func setState(tvhserver: TvhServer, metadata: VideoMetadata) {
        tvh = tvhserver
        videoMetadata = metadata
    }
    
    func completeInitialization() {
        guard let meta = videoMetadata else { return }
        guard let url = tvh?.getVideoURL(video: meta) else { return }
        
        if player == nil {
            let pl = VLCMediaPlayer()
            //pl.libraryInstance.debugLogging = true
            //pl.libraryInstance.debugLoggingLevel = 0
            pl.drawable = movieView
            pl.delegate = self
            player = pl
        }
        
        player!.media = VLCMedia(url: url)
        player!.play()
    }
    
    private func exit() {
        navigationController?.popViewController(animated: true)
    }
    
    private func playPause() {
        guard let pl = player else { return }
        if pl.isPlaying {
            pl.pause()
        } else {
            pl.play()
        }
    }
    
    private func fastForward(delta: Int) {
        guard let pl = self.player else { return }
        fastForwardRate = fastForwardRate + delta
        if fastForwardRate < -4 || fastForwardRate > 4 {
            fastForwardRate = 0
        }
        
        if fastForwardRate < 0 {
            pl.fastForward(atRate: Float(fastForwardRate))
        } else {
            pl.fastForward(atRate: Float(fastForwardRate+1))
        }
    }
    
    private func addTapGestureRecognizer(toview: UIView, button: UIPress.PressType, selector: Selector) {
        let recognizer = UITapGestureRecognizer(target: self, action: selector)
        recognizer.allowedPressTypes = [NSNumber(integerLiteral: button.rawValue)]
        toview.addGestureRecognizer(recognizer)
    }
    
    private func addSwipeGestureRecognizer(toview: UIView, direction: UISwipeGestureRecognizer.Direction, selector: Selector) {
        let recognizer = UISwipeGestureRecognizer(target: self, action: selector)
        recognizer.direction = direction
        toview.addGestureRecognizer(recognizer)
    }
    
    private func addPanGestureRecognizer(toview: UIView, selector: Selector) {
        let recognizer = UIPanGestureRecognizer(target: self, action: selector)
        toview.addGestureRecognizer(recognizer)
    }
    
    
    private func getAudioTracks() -> [TrackInfo] {
        return getTracks(type: "audio", indexes: self.player?.audioTrackIndexes, names: self.player?.audioTrackNames)
    }
    
    private func getSubtitleTracks() -> [TrackInfo] {
        return getTracks(type: "subtitle", indexes: self.player?.videoSubTitlesIndexes, names: self.player?.videoSubTitlesNames)
    }
    
    private func getTracks(type: String, indexes: [Any]?, names: [Any]?) -> [TrackInfo] {
        guard let indexes = indexes, let names = names else { return [] }
        
        var tmpindexes:[Int32] = []
        for index in indexes {
            if let index = index as? NSNumber {
                tmpindexes.append(index.int32Value)
            }
        }
        var tmpnames:[String] = []
        for name in names {
            if let name = name as? String {
                tmpnames.append(name)
            }
        }
        
        let count = tmpindexes.count
        if count != tmpnames.count {
            print("\(type) indexes do not match \(type) names")
            return []
        }
        
        var tracks: [TrackInfo] = []
        for i in 0..<count {
            tracks.append(TrackInfo(trackid: tmpindexes[i], description: tmpnames[i]))
        }
        
        return tracks
    }
    
    
    // Main view gesture handlers.
    //
    
    @objc func handleMainTapSelect(_ sender: UITapGestureRecognizer) {
        updateTimeProgress()

        let width = timeView.frame.width
        let height = timeView.frame.height
        let screenheight:CGFloat = 1080
        timeView.frame = CGRect(x: 0, y: screenheight, width: width, height: height)
        timeView.isHidden = false
        shouldUpdateTime = true
        setNeedsFocusUpdate()
        UIView.animate(withDuration: 1.0, animations: {
            self.timeView.frame = CGRect(x: 0, y: screenheight-height, width: width, height: height)
        })
    }
    
    @objc func handleTapPlay(_ sender: UITapGestureRecognizer) {
        playPause()
    }
    
    @objc func handleVideoSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        guard let pl = player else { return }
        if pl.media.length.intValue == 0 {
            fastForward(delta: -1)
        } else {
            pl.jumpBackward(jumpBackwardSeconds)
        }
    }
    
    @objc func handleVideoSwipeRight(_ sender: UISwipeGestureRecognizer) {
        guard let pl = player else { return }
        if pl.media.length.intValue == 0 {
            fastForward(delta: 1)
        } else {
            pl.jumpForward(jumpForwardSeconds)
        }
    }
    
    @objc func handleVideoSwipeDown(_ sender: UISwipeGestureRecognizer) {
        print("video swipe down")
        audioTracks = getAudioTracks()
        subtitleTracks = getSubtitleTracks()
        if let player=player {
            selectedAudioTrack = player.currentAudioTrackIndex
            selectedSubtitleTrack = player.currentVideoSubTitleIndex
        }
        audioCollectionView.reloadData()
        subtitlesCollectionView.reloadData()
        
        let width = settingsView.frame.width
        let height = settingsView.frame.height
        settingsView.frame = CGRect(x: 0, y: -height, width: width, height: height)
        settingsView.isHidden = false
        setNeedsFocusUpdate()
        UIView.animate(withDuration: 1.0, animations: {
            self.settingsView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        })
    }
    
    // Time view gesture handlers
    //
    
    @objc func handleTimeTapMenu(_ sender: UITapGestureRecognizer) {
        let width = timeView.frame.width
        let height = timeView.frame.height
        let screenheight:CGFloat = 1080
        shouldUpdateTime = false
        UIView.animate(withDuration: 1.0, animations: {
            self.timeView.frame = CGRect(x: 0, y: screenheight, width: width, height: height)
            }, completion: { (_) in
                self.timeView.isHidden = true
                self.setNeedsFocusUpdate()
            })
    }

    @objc func handleTimePan(_ sender: UIPanGestureRecognizer) {
        guard let pl = player else { return }
        
        if sender.state == .began {
            shouldUpdateTime = false
            pl.pause()
            panOriginPosition = pl.position
        }
        
        let viewwidth = timeView.frame.width
        var updatedPos = panOriginPosition + Float(sender.translation(in: timeView).x / viewwidth)
        
        if updatedPos < 0 {
            updatedPos = 0
        } else if updatedPos > 1.0 {
            updatedPos = 1.0
        }
        
        progressView.progress = updatedPos
        pl.position = updatedPos
        
        if sender.state == .ended {
            shouldUpdateTime = true
            pl.play()
        }
    }
    
    // Settings view gesture handlers
    //
    
    @objc func handleSettingsTapSelect(_ sender: UITapGestureRecognizer) {
        guard let focusedCell = UIScreen.main.focusedView as? SettingsCollectionViewCell else { return }
        if focusedCell.isAudioTrack {
            selectedAudioTrack = focusedCell.trackID
            player?.currentAudioTrackIndex = selectedAudioTrack
            audioCollectionView.reloadData()
        } else {
            selectedSubtitleTrack = focusedCell.trackID
            player?.currentVideoSubTitleIndex = selectedSubtitleTrack
            subtitlesCollectionView.reloadData()
        }
    }
    
    @objc func handleSettingsTapMenu(_ sender: UITapGestureRecognizer) {
        let width = settingsView.frame.width
        let height = settingsView.frame.height
        settingsView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        UIView.animate(withDuration: 1.0, animations: {
            self.settingsView.frame = CGRect(x: 0, y: -height, width: width, height: height)
        }, completion: { _ in
            self.settingsView.isHidden = true
            self.setNeedsFocusUpdate()
        })
    }
    
    // Collection View Methods
    //
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == audioCollectionView {
            return audioTracks.count
        }
        if collectionView == subtitlesCollectionView {
            return subtitleTracks.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == audioCollectionView {
            let cell: SettingsCollectionViewCell = audioCollectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifierTitle, for: indexPath) as! SettingsCollectionViewCell
            let track = audioTracks[indexPath.row]
            cell.setState(isaudio: true, selected: (track.trackid == selectedAudioTrack), trackid: track.trackid, description: track.description)
            return cell
        }
        if collectionView == subtitlesCollectionView {
            let cell: SettingsCollectionViewCell = subtitlesCollectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifierTitle, for: indexPath) as! SettingsCollectionViewCell
            let track = subtitleTracks[indexPath.row]
            cell.setState(isaudio: false, selected: (track.trackid == selectedSubtitleTrack), trackid: track.trackid, description: track.description)
            return cell
        }
        return UICollectionViewCell()
    }
    
    // VLCMediaPlayerDelegate
    //
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        guard let pl = aNotification.object as? VLCMediaPlayer else { return }
        if pl.state == .ended {
            exit()
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if timeView.isHidden { return }
        updateTimeProgress()
    }
    
    private func updateTimeProgress() {
        guard let pl = player else { return }
        if !shouldUpdateTime { return }
        progressView.progress = pl.position
        timeLabel.text = pl.time.stringValue
        
        let remaining = pl.remainingTime
        if remaining == VLCTime.null() {
            remainingTimeLabel.text = ""
        } else {
            remainingTimeLabel.text = remaining?.stringValue
        }
    }
}
