//
//  ViewController.swift
//
//  Created by gh on 2022/7/1.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    lazy var tableView:UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.backgroundColor = UIColor.clear
        table.register(contentCell.self, forCellReuseIdentifier: "contentCell")
        return table
    }()
    
    var dataList:[(String,Bool)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        dataList = [
            ("跌倒，\n撞墙，\n一败涂地，\n都不用害怕，\n年轻叫你勇敢。",false),
            ("今天看到一句话：\n主动选择孤独的人，其实并不孤独。\n真正孤独的人，是那些试图挤进人群的人。\n最近嗜睡，许是时光荏苒，弥补错过的春天。\n纵然岁月如梭，只要有梦，每一个春天都不曾逝去，每一个冬季都不曾来临。\n只要在自己的世界里活得精彩，管他是醒是梦呢。\n一个人待在房间，常常夜里很安静，有时候静得掉地上一根针都能听得见。\n能安静地呆着，也是一件很享受的事情，叫做宁静且享受孤独。\n用自己喜欢的方式，去感受时光流逝，去体验生命的变化。",false),
            ("一个人应当摈弃那些令人心颤的杂念，全神贯注地走自己脚下的人生之路。",false),
            ("觉得自己做得到和做不到，只在一念之间。",false),
        ]
        
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contentCell", for: indexPath)
        if let cell = cell as? contentCell {
            let model = dataList[indexPath.section]
            cell.setData(content: model.0, type: model.1)
            cell.titleLb.handleActionTap {[weak self] type in
                self?.showAllBtnAction(index: indexPath.section, type: type)
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = dataList[indexPath.section]
        let height = contentCell.cellHeight(content: model.0, isShowAll: model.1)
        return height
    }
    
    func showAllBtnAction(index:Int, type:GHFoldLabelActionType) {
        if dataList.count > index {
            var model = dataList[index]
            model.1 = type == .spread
            dataList[index] = model
            tableView.beginUpdates()
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index)) {
                if let cell = cell as? contentCell {
                    cell.setData(content: model.0, type: model.1)
                }
            }
            tableView.endUpdates()
        }
    }
}


class contentCell: UITableViewCell {
    
    let titleLb = GHFoldLabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1000))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.2)
        selectionStyle = .none
        clipsToBounds = true
        
        contentView.addSubview(titleLb)
        titleLb.translatesAutoresizingMaskIntoConstraints = false
        titleLb.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true  //顶部约束
        titleLb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true  //左端约束
        titleLb.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true  //右端约束
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(content:String, type:Bool) {
        titleLb.minimumLine = 3
        titleLb.activedType = type ? .fold : .spread
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 10
        paragraphStyle.minimumLineHeight = 14
        titleLb.attributedText = NSMutableAttributedString(string: content, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14),NSAttributedString.Key.paragraphStyle:paragraphStyle,NSAttributedString.Key.foregroundColor:UIColor.white])
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = titleLb.sizeThatFits(CGSize(width: UIScreen.main.bounds.width-32, height: CGFloat.greatestFiniteMagnitude))
        let result = CGSize(width: self.bounds.width,height: size.height + 16)
        return result
    }
    
    class func cellHeight(content:String, isShowAll:Bool) -> CGFloat {
        let cell = self.init()
        cell.setData(content: content, type: isShowAll)
        let height = cell.sizeThatFits(CGSize.zero).height
        return height
    }
}

