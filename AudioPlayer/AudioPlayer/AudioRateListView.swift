//
//  AudioRateListView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/12/8.
//

import UIKit

class AudioRateListCell: UITableViewCell {
    
    lazy var titleLabel = UILabel().then { (label) in
        label.textColor = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 14)
    }
    lazy var radioButton = UIButton().then { (button) in
        button.setImage(UIImage(named: "audio_rate_normal"), for: .normal)
        button.setImage(UIImage(named: "audio_rate_selected"), for: .selected)
    }
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(radioButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(12)
        }
        radioButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-18)
        }
    }
}

class AudioRateModel {
    var title:String
    var isSelected:Bool
    
    init(_ title:String,_ isSelected:Bool) {
        self.title = title
        self.isSelected = isSelected
    }
}

class AudioRateListView: UIView,UITableViewDelegate,UITableViewDataSource {

    lazy var tableView:UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.register(AudioRateListCell.self, forCellReuseIdentifier: "AudioRateListCell")
        view.showsVerticalScrollIndicator = false
        view.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.separatorColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
        return view
    }()
    
    lazy var footerButton = UIButton().then { (button) in
        button.backgroundColor = .white
        button.setTitle("关闭", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 1), for: .normal)
    }
    
    lazy var containerView = UIView().then { (view) in
        view.backgroundColor = .white
    }
    
    var rateSelectComplete:((Float)->())?
    
    var datas:[AudioRateModel] = [AudioRateModel("0.5", false),
                                  AudioRateModel("1.0",true),
                                  AudioRateModel("1.5", false),
                                  AudioRateModel("2.0",false)]
    
    var lastSelectedIndexPath:IndexPath!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addSubview(containerView)
        containerView.addSubview(tableView)
        footerButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        tableView.reloadData()
        lastSelectedIndexPath = IndexPath(row: 1, section: 0)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = CGRect(x: 0, y: kScreenHeight, width: kScreenWidth, height: 218)
        tableView.frame = CGRect(x: 0, y: 6, width: kScreenWidth, height: 212)
        footerButton.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: 48)
        tableView.tableFooterView = footerButton
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioRateListCell") as! AudioRateListCell
        cell.titleLabel.text = datas[indexPath.row].title + "x"
        cell.radioButton.isSelected = datas[indexPath.row].isSelected
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let lastModel = datas[lastSelectedIndexPath.row]
        lastModel.isSelected = false
        
        let model = datas[indexPath.row]
        model.isSelected = true
        
        lastSelectedIndexPath = indexPath
        
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.rateSelectComplete?(Float(model.title) ?? 1.0)
            self.dismiss()
        }
        
    }
   
    
    @objc func dismiss() {
        var originFrame = containerView.frame
        UIView.animate(withDuration: 0.2) {
            originFrame.origin.y = self.height
            self.containerView.frame = originFrame
           
        } completion: { (flag) in
            UIView.animate(withDuration: 0.2) {
                self.alpha = 0
            } completion: { (flag) in
                self.removeFromSuperview()
            }

        }
    }
    
    func show() {
        self.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        let window = UIApplication.shared.keyWindow
        window?.addSubview(self)
        layoutIfNeeded()
        setNeedsLayout()
        var originFrame = containerView.frame
        self.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        } completion: { (flag) in
            UIView.animate(withDuration: 0.2) {
                originFrame.origin.y = self.height - 218
                self.containerView.frame = originFrame
            }
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }
}
