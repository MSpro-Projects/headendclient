//
//  SettingsViewController.swift
//  TVHeadend Client
//
//  Created by Kin Wai Koo on 2019-01-01.
//

import TVUIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var port: UITextField!
    @IBOutlet weak var refreshButton: UIButton!
    
    
    let titleViewControllerIndex = 0
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        address.text = defaults.object(forKey: "serveraddress") as? String ?? ""
        var p = defaults.integer(forKey: "serverport")
        if p == 0 { p = 9981 }
        port.text = String(p)
        
        if let buttonText = refreshButton.currentTitle {
            refreshButton.setTitle(buttonText + " ✅", for: .disabled)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshButton.isEnabled = true
    }
    
    @IBAction func addressChanged(_ sender: Any) {
        defaults.set(address.text, forKey: "serveraddress")
        refreshData()
    }
    
    @IBAction func portChanged(_ sender: Any) {
        guard let s = port.text else { return }
        guard let p = Int(s) else { return }
        defaults.set(p, forKey: "serverport")
        refreshData()
    }
    
    @IBAction func refreshServerData(_ sender: Any) {
        refreshButton.isEnabled = false
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        refreshData()
    }
    private func refreshData() {
        guard let vc = self.tabBarController?.viewControllers else { return }
        if vc.count == 0 { return }
        guard let tvc = vc[0] as? TitleViewController else { return }
        tvc.refreshData = true
    }
}
