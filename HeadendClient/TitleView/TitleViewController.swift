//
//  TitleViewController.swift
//  HeadendClient
//
//  Created by Kin Wai Koo on 26/1/19.
//  Parts of this code were copied from http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/.
//

import Foundation
import UIKit

class TitleViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, TvhClient {
    @IBOutlet weak var waitView : UIView!
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    let reuseIdentifierTitle = "TitleCollectionViewCell"
    let settingsViewIndex = 1
    
    var tvh : TvhServer?
    var titles : [String] = []
    var refreshData = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if refreshData {
            scrollView.isHidden = true
            waitView.isHidden = false
            activityIndicator.startAnimating()
            
            do {
                let defaults = UserDefaults.standard
                tvh = try TvhServer(serverAddress: defaults.object(forKey: "serveraddress") as? String ?? "", serverPort: defaults.integer(forKey: "serverport"))
                tvh!.loadRecordedPrograms(client: self)
            } catch let err {
                showAlert(message: err.localizedDescription)
            }
            refreshData = false
        }
        
    }
    
    
    func recordedProgramsLoaded(error: Error?) {
        if let err = error {
            showAlert(message: err.localizedDescription)
            return
        }
        
        guard let tvh=self.tvh else {
            showAlert(message: "Coult not connect to server.")
            return
        }
        self.titles = tvh.getTitles()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.activityIndicator.stopAnimating()
            self.waitView.isHidden = true
            self.scrollView.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTitle" {
            guard let cell = sender as? TitleCollectionViewCell else { return }
            guard let dest = segue.destination as? EpisodeViewController else { return }
            
            guard let tvh = self.tvh, let title = cell.titleLabel.text else { return }
            dest.setState(tvhserver: tvh, title: title)
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Server Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Edit Settings", style: .default, handler: { _ in
                DispatchQueue.main.async {
                    self.tabBarController!.selectedIndex = self.settingsViewIndex
                    self.refreshData = true
                }
            }))
            self.present(alert, animated: true, completion: nil)
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
            return titles.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == self.collectionView) {
            let cell : TitleCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifierTitle, for: indexPath) as! TitleCollectionViewCell
            cell.setState(text: titles[indexPath.row])
            
            return cell
        }
        return UICollectionViewCell()
    }
}
