//
//  NCCreateFormUploadConflict.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 29/03/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

@objc class NCCreateFormUploadConflict: UIViewController {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubTitle: UILabel!

    @IBOutlet weak var switchNewFiles: UISwitch!
    @IBOutlet weak var switchAlreadyExistingFiles: UISwitch!

    @IBOutlet weak var labelNewFiles: UILabel!
    @IBOutlet weak var labelAlreadyExistingFiles: UILabel!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var buttonCancel: UIButton!
    @IBOutlet weak var buttonContinue: UIButton!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @objc var metadatas: [tableMetadata]
    @objc var metadatasConflict: [tableMetadata]
    
    var metadatasConflictNewFiles = [String]()
    var metadatasConflictAlreadyExistingFiles = [String]()


    @objc required init?(coder aDecoder: NSCoder) {
        self.metadatas = [tableMetadata]()
        self.metadatasConflict = [tableMetadata]()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        tableView.register(UINib.init(nibName: "NCCreateFormUploadConflictCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        labelTitle.text = String(metadatasConflict.count) + " " + NSLocalizedString("_file_conflict_num_", comment: "")
        labelSubTitle.text = NSLocalizedString("_file_conflict_desc_", comment: "")
        labelNewFiles.text = NSLocalizedString("_file_conflict_new_", comment: "")
        labelAlreadyExistingFiles.text = NSLocalizedString("_file_conflict_exists_", comment: "")
        
        switchNewFiles.isOn = false
        switchAlreadyExistingFiles.isOn = false
        
        buttonCancel.layer.cornerRadius = 20
        buttonCancel.layer.masksToBounds = true
        buttonCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        buttonCancel.layer.backgroundColor = NCBrandColor.sharedInstance.graySoft.withAlphaComponent(0.5).cgColor
        
        buttonContinue.layer.cornerRadius = 20
        buttonContinue.layer.masksToBounds = true
        buttonContinue.setTitle(NSLocalizedString("_continue_", comment: ""), for: .normal)
        buttonContinue.isEnabled = false
        buttonContinue.setTitleColor(.lightGray, for: .normal)
        buttonContinue.layer.backgroundColor = NCBrandColor.sharedInstance.graySoft.withAlphaComponent(0.5).cgColor
    }
    
    @IBAction func valueChangedSwitchNewFiles(_ sender: Any) {
        metadatasConflictNewFiles.removeAll()

        if switchNewFiles.isOn {
            for metadata in metadatasConflict {
                metadatasConflictNewFiles.append(metadata.ocId)
            }
        }
        
        tableView.reloadData()
        
        canContinue()
    }
    
    @IBAction func valueChangedSwitchAlreadyExistingFiles(_ sender: Any) {
        metadatasConflictAlreadyExistingFiles.removeAll()
        
        if switchAlreadyExistingFiles.isOn {
            for metadata in metadatasConflict {
                metadatasConflictAlreadyExistingFiles.append(metadata.ocId)
            }
        }
        
        tableView.reloadData()
        
        canContinue()
    }
    
    @IBAction func buttonCancelTouch(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func buttonContinueTouch(_ sender: Any) {
        
    }
}

// MARK: - UITableViewDelegate

extension NCCreateFormUploadConflict: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 135
    }
}

// MARK: - UITableViewDataSource

extension NCCreateFormUploadConflict: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metadatasConflict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? NCCreateFormUploadConflictCell {
            
            let metadata = metadatasConflict[indexPath.row]
            
            cell.ocId = metadata.ocId
            cell.delegate = self
            
            if FileManager().fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, fileNameView: metadata.fileName)) {
                NCUtility.sharedInstance.loadImage(ocId: metadata.ocId, fileNameView: metadata.fileNameView) { (image) in
                    cell.imageFile.image = image
                }
            } else {
                if metadata.iconName.count > 0 {
                    cell.imageFile.image = UIImage.init(named: metadata.iconName)
                } else {
                    cell.imageFile.image = UIImage.init(named: "file")
                }
            }
            
            cell.labelFileName.text = metadata.fileNameView
            cell.labelDetail.text = CCUtility.dateDiff(metadata.date as Date) + ", " + CCUtility.transformedSize(metadata.size)
                        
            if metadatasConflictNewFiles.contains(metadata.ocId) {
                cell.switchNewFile.isOn = true
            } else {
                cell.switchNewFile.isOn = false
            }
            
            if metadatasConflictAlreadyExistingFiles.contains(metadata.ocId) {
                cell.switchAlreadyExistingFile.isOn = true
            } else {
                cell.switchAlreadyExistingFile.isOn = false
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
}

// MARK: - NCCreateFormUploadConflictCellDelegate

extension NCCreateFormUploadConflict: NCCreateFormUploadConflictCellDelegate {
    
    func valueChangedSwitchNewFile(with ocId: String, isOn: Bool) {
        if let index = metadatasConflictNewFiles.firstIndex(of: ocId) {
            metadatasConflictNewFiles.remove(at: index)
        }
        if isOn {
            metadatasConflictNewFiles.append(ocId)
        }
        if metadatasConflictNewFiles.count == metadatasConflict.count {
            switchNewFiles.isOn = true
        } else {
            switchNewFiles.isOn = false
        }
        
        canContinue()
    }
    
    func valueChangedSwitchAlreadyExistingFile(with ocId: String, isOn: Bool) {
        if let index = metadatasConflictAlreadyExistingFiles.firstIndex(of: ocId) {
            metadatasConflictAlreadyExistingFiles.remove(at: index)
        }
        if isOn {
            metadatasConflictAlreadyExistingFiles.append(ocId)
        }
        if metadatasConflictAlreadyExistingFiles.count == metadatasConflict.count {
            switchAlreadyExistingFiles.isOn = true
        } else {
            switchAlreadyExistingFiles.isOn = false
        }
        
        canContinue()
    }
    
    func canContinue() {
        var result = true
        for metadata in metadatasConflict {
            if !metadatasConflictNewFiles.contains(metadata.ocId) && !metadatasConflictAlreadyExistingFiles.contains(metadata.ocId) {
                result = false
            }
        }
        
        if result {
            buttonContinue.isEnabled = true
            buttonContinue.setTitleColor(.black, for: .normal)
        } else {
            buttonContinue.isEnabled = false
            buttonContinue.setTitleColor(.lightGray, for: .normal)
        }
    }
}
