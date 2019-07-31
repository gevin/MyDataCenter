//
//  ViewController.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/24.
//  Copyright © 2019 GevinChen. All rights reserved.
//

import UIKit
import SDWebImage
import SVProgressHUD

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DataCenterListener {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            let nib = UINib(nibName: "UserCell", bundle: nil)
            self.tableView.register(nib, forCellReuseIdentifier: "UserCell")
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }
    
    var cellModels: [UserCellModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Repository<UserModel>.deleteAll()
        
        let userList = self.readJSONFile()
        Repository<UserModel>.insertBatch(objects: userList)
        Repository<UserModel>.addListener(listener: self)
        
    }
    
    // MARK: - DataCenter Listener
    // 當 UserModel table 發生新增、修改、刪除 會觸發
    func dataModelChanged(change: ModelChange) {
        let allUser = Repository<UserModel>.fetchAll()
        self.reloadModel(userModels: allUser)
    }
    
    // MARK: - Action
    
    @IBAction func queryClicked(_ sender: Any) {
        let userList = Repository<UserModel>.fetchAll()
        self.reloadModel(userModels: userList)
    }
    
    @IBAction func updateClicked(_ sender: Any) {
        let userList1 = Repository<UserModel>.fetch(condition: "userId == 0", limit: 1)
        if userList1.count > 0 {
            let userModel = userList1[0]
            userModel.email = "updateTest@example.com"
            userModel.dob?.age = Int32(Int.random(in: 0...100))
            // 改完值後，下個 runloop 會自動儲存
        }
    }
    
    @IBAction func addNewClicked(_ sender: Any) {
        self.fetchNewUser { (newUserList:[UserModel]) in
            Repository<UserModel>.insertOrUpdateBatch(objects: newUserList, primaryKeys: ["userId"])
        }
    }
    
    @objc
    func removeUserModel( userId: String ) {
        Repository<UserModel>.delete(condition: "userId == '\(userId)'", arguments: nil)
        let userList = Repository<UserModel>.fetchAll()
        self.reloadModel(userModels: userList)
    }
    
    // MARK: - Operation
    
    /**
     
     Random User 網址
      https://randomuser.me/
     
     隨機撈一筆假的個人資料
      https://randomuser.me/api/
     
     */
    func fetchNewUser( handler: @escaping (_ userModels: [UserModel]) -> Void ) {
        
        let request = NSMutableURLRequest(url: URL(string: "https://randomuser.me/api/")! )
        request.httpMethod = "GET"
        
        SVProgressHUD.show()
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {[weak self] (dataOpt:Data?, responseOpt:URLResponse?, errorOpt:Error?) in
            SVProgressHUD.dismiss()
            guard let strongSelf = self else {return}
            do {
                guard let jsondata = dataOpt else {return}
                guard let jsondict = try JSONSerialization.jsonObject(with: jsondata, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] else {
                    print("json string parse fail.")
                    return
                }
                
                if let userDataList = jsondict["results"] as? [[String:Any]] {
                    let decoder = JSONDecoder()
                    var models: [UserModel] = []
                    for userdict in userDataList {
                        let userData = try JSONSerialization.data(withJSONObject: userdict, options: JSONSerialization.WritingOptions.prettyPrinted)
                        let userModel = try decoder.decode(UserModel.self, from: userData)
                        userModel.userId = UUID().uuidString
                        models.append(userModel)
                    }
                    DispatchQueue.main.async {
                        handler(models)
                    }
                }
                
            } catch {
                print(error)
            }
            })
        
        task.resume()
        
    }
    
    // 從 randomuser.json 讀出 json 並轉成 UserModel
    func readJSONFile() -> [UserModel] {
        
        guard let path = Bundle.main.path(forResource: "randomuser", ofType: "json") else {return [] }
        
        do {
            let jsondata = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let jsondict = try JSONSerialization.jsonObject(with: jsondata, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] else {
                print("json string parse fail.")
                return []
            }
            if let userDataList = jsondict["results"] as? [[String:Any]] {
                let decoder = JSONDecoder()
                var models: [UserModel] = []
                var index = 0
                for userdict in userDataList {
                    let userData = try JSONSerialization.data(withJSONObject: userdict, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let userModel = try decoder.decode(UserModel.self, from: userData)
                    userModel.userId = "\(index)"
                    index += 1
                    models.append(userModel)
                }
                return models
            }
            
        }catch {
            print(error)
        }
        return []
    }
    
    // 從 randomuser2.json 讀出 json 並轉成 UserModel
    // 大致內容跟 randomuser.json 一樣，只有幾個欄位做修改，主要測 insertOrUpdateBatch
    // 
    func readJSONFile2() -> [UserModel] {
        
        guard let path = Bundle.main.path(forResource: "randomuser2", ofType: "json") else {return []}
        
        do {
            let jsondata = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let jsondict = try JSONSerialization.jsonObject(with: jsondata, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] else {
                print("json string parse fail.")
                return []
            }
            if let userDataList = jsondict["results"] as? [[String:Any]] {
                let decoder = JSONDecoder()
                var models: [UserModel] = []
                var index = 0
                for userdict in userDataList {
                    let userData = try JSONSerialization.data(withJSONObject: userdict, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let userModel = try decoder.decode(UserModel.self, from: userData)
                    userModel.userId = "\(index)"
                    index += 1
                    models.append(userModel)
                }
                return models
            }
        }catch {
            print(error)
        }
        return []
    }
    
    func reloadModel( userModels: [UserModel] ) {
        self.cellModels.removeAll()
        for userModel in userModels {
            
            var cellModel = UserCellModel(userId: userModel.userId ?? "", 
                                          userPic: nil, 
                                          userName: "\(userModel.name?.first ?? "") \(userModel.name?.last ?? "")", 
                                          location: "\(userModel.location?.postcode ?? ""), \(userModel.location?.street ?? ""), \(userModel.location?.city ?? ""), \(userModel.location?.state ?? "")", 
                                          email: userModel.email ?? "",
                                          phone: userModel.phone ?? "",
                                          birthday: userModel.dob?.date ?? "", 
                                          age: Int(userModel.dob?.age ?? 0) )
            cellModel.setAction(target: self, method: #selector(removeUserModel(userId:)))
            
            if let pic_url = userModel.picture?.medium {
                SDWebImageDownloader.shared.downloadImage(with: URL(string:pic_url), completed: {[weak self] (imageOpt:UIImage?, dataOpt:Data?, errorOpt:Error?, finish:Bool) -> Void in
                    guard let strongSelf = self else {return}
                    
                    cellModel.setUserPic(image: imageOpt)
                    if let index = strongSelf.cellModels.firstIndex(where: {$0.userId == cellModel.userId}) {
                        strongSelf.cellModels[index] = cellModel
                        strongSelf.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableView.RowAnimation.automatic)
                    }
                })
            }
            
            self.cellModels.append(cellModel)
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellModel = self.cellModels[indexPath.row] 
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        
        cell.userPicImageView.image = cellModel.userPic
        cell.userNameLabel.text = cellModel.userName
        cell.ageLabel.text = "\(cellModel.age)"
        cell.emailLabel.text = cellModel.email
        cell.birthdayLabel.text = cellModel.birthday
        cell.phoneLabel.text = cellModel.phone
        cell.cellModel = cellModel
        return cell
    }
    
}

