//
//  UserCell.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    
    @IBOutlet weak var userPicImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    var cellModel: UserCellModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func deleteClicked(_ sender: Any) {
        if cellModel != nil {
            cellModel?.performAction()
        }
    }
}
