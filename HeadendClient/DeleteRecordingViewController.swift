//
//  DeleteRecordingViewController.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 2019-01-01.
//

import TVUIKit

protocol DeleteRecordingDelegate {
    func deleteRecordingSuccessful(metadata: VideoMetadata)
}

class DeleteRecordingViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    private var tvh: TvhServer?
    private var metadata: VideoMetadata?
    private var delegate: DeleteRecordingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.isHidden = true
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleMenuTap(_:)))
        recognizer.allowedPressTypes = [NSNumber(integerLiteral: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(recognizer)
        
        guard let metadata = self.metadata else { return }
        titleLabel.text = metadata.title
        subtitleLabel.text = metadata.subtitle ?? ""
        
        let tzOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        var time = DateFormatter.localizedString(from: metadata.getStartTimeAsDate() + tzOffset, dateStyle: .short, timeStyle: .short)
        time.append(" - ")
        time.append(DateFormatter.localizedString(from: metadata.getStopTimeAsDate() + tzOffset, dateStyle: .short, timeStyle: .short))
        timeLabel.text = time
    }
    
    func setState(deleteDelegate: DeleteRecordingDelegate, tvhserver: TvhServer, videometadata: VideoMetadata) {
        delegate = deleteDelegate
        tvh = tvhserver
        metadata = videometadata
    }
    
    @IBAction func confirmDeletion(_ sender: Any) {
        guard let metadata = self.metadata else { return }
        cancelButton.isEnabled = false
        confirmButton.isEnabled = false
        spinner.isHidden = false
        spinner.startAnimating()
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        DispatchQueue.global(qos: .background).async {
            // todo: call tvh delete function here
            sleep(20)
            
            // if no errors,
            self.delegate?.deleteRecordingSuccessful(metadata: metadata)
            
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.spinner.isHidden = true
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        cancel()
    }
    
    @objc func handleMenuTap(_ sender: UITapGestureRecognizer) {
        cancel()
    }
    
    private func cancel() {
        if spinner.isHidden {
            dismiss(animated: true, completion: nil)
        }
    }
}
