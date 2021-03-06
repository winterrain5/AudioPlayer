//
//  VideoRateView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/12/7.
//

import UIKit

class VideoRateView: UIView {

    var backgroundImageView = UIImageView()
    var statckView = UIStackView()
    var selectedButton:UIButton!
    var rateSelectComplete:((Float)->())?
    var rate = ["2.0","1.5","1.0","0.5"]
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        backgroundImageView.isUserInteractionEnabled = true
        addSubview(backgroundImageView)
        backgroundImageView.image = UIImage(named: "rate_cover_background")
        
        addSubview(statckView)
        statckView.axis = .vertical
        statckView.alignment = .center
        statckView.backgroundColor = .clear
        for i in 0...(rate.count - 1){
            let button = UIButton()
            button.tag = i
            button.setTitle(rate[i] + "x", for: .normal)
            button.titleLabel?.textColor = UIColor.white
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            button.addTarget(self, action: #selector(rateAction(_:)), for: .touchUpInside)
            button.setBackgroundImage(UIImage(named: "rate_selected_background"), for: .selected)
            button.setBackgroundImage(nil, for: .normal)
            statckView.addArrangedSubview(button)
            if i == 2 {
                
                selectedButton = button
                selectedButton.isSelected.toggle()
            }
        }
        
    }
    
    @objc func rateAction(_ sender:UIButton) {
        sender.isSelected.toggle()
        selectedButton.isSelected.toggle()
        selectedButton = sender
        rateSelectComplete?(Float(rate[sender.tag]) ?? 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.alpha = 0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        statckView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(144)
            make.width.equalTo(227)
        }
        
        for (i,button) in statckView.arrangedSubviews.enumerated() {
            button.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(36)
                make.top.equalToSuperview().offset(i * 36)
            }
        }
    }

}
