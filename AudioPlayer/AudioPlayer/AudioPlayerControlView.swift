//
//  AudioPlayerControlView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit

protocol AudioPlayerControlViewDelegate:NSObjectProtocol {
    
    // 按钮点击
    func controlView(controlView:AudioPlayerControlView, didClickPrev:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickPlay:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickNext:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickRate rate:Float)
    
    // 滑竿滑动及点击
    func controlView(controlView:AudioPlayerControlView, didSliderTouchBegan value:Float)
    func controlView(controlView:AudioPlayerControlView, didSliderTouchEnded value:Float)
    func controlView(controlView:AudioPlayerControlView, didSliderValueChange value:Float)
    func controlView(controlView:AudioPlayerControlView, didSliderTapped value:Float)
    
}

class AudioPlayerControlView: UIView, AudioPlayerSliderDelegate {
    weak var delegate:AudioPlayerControlViewDelegate?
    
    var currentTime:String = "" {
        didSet {
            self.currentLabel.text = currentTime
        }
    }
    var totalTime:String = "" {
        didSet {
            self.totalLabel.text = totalTime
        }
    }
    var progress:Float = 0 {
        didSet {
            sliderView.value = progress
        }
    }
    var bufferProgress:Float = 0 {
        didSet {
            sliderView.bufferValue = bufferProgress
        }
    }
    
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var preButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var sliderContainer: UIView!
    
    lazy var rateListView = AudioRateListView()
    
    lazy var sliderView:AudioPlayerSliderView = {
        let view = AudioPlayerSliderView()
        view.delegate = self
        view.minmunTrackImage = UIImage(named: "slider_progress")
        view.maximumTrackImage = UIImage(named: "slider_track")
        view.thumbImage = UIImage(named: "slider_dot")
        view.sliderHeight = 2
        view.sliderCorner = 1
        view.thumbImageSize = CGSize(width: 6, height: 10)
        return view
    }()
    override func awakeFromNib() {
        super.awakeFromNib()
        
        rateButton.layer.cornerRadius = 5
        rateButton.layer.masksToBounds = true
        rateButton.layer.borderWidth = 1
        rateButton.layer.borderColor = UIColor.white.cgColor
        
        sliderContainer.addSubview(sliderView)
        
        rateListView.rateSelectComplete = {
            [weak self] rate in
            guard let `self` = self else { return }
            self.delegate?.controlView(controlView: self, didClickRate: rate)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
 
    @IBAction func preAction(_ sender: UIButton) {
        self.delegate?.controlView(controlView: self, didClickPrev: sender)
    }
    @IBAction func playAction(_ sender: UIButton) {
        self.delegate?.controlView(controlView: self, didClickPlay: sender)
    }
    @IBAction func nextAction(_ sender: UIButton) {
        self.delegate?.controlView(controlView: self, didClickNext: sender)
    }
   
    @IBAction func rateAction(_ sender: Any) {
        rateListView.show()
    }
    
    func setupPlayBtn() {
        playButton.setImage(UIImage(named: "audio_pause"), for: .normal)
    }
    
    func setupPauseBtn() {
        playButton.setImage(UIImage(named: "audio_play"), for: .normal)
    }
    
    func showLoading() {
        sliderView.showLoading()
    }
    
    func hideLoading() {
        sliderView.hideLoading()
    }
    
    func sliderTouchBegan(value: Float) {
        self.delegate?.controlView(controlView: self, didSliderTouchBegan: value)
    }
    
    func sliderValueChanged(value: Float) {
        self.delegate?.controlView(controlView: self, didSliderValueChange: value)
    }
    
    func sliderTouchEnded(value: Float) {
        self.delegate?.controlView(controlView: self, didSliderTouchEnded: value)
    }
    
    func sliderTapped(value: Float) {
        self.delegate?.controlView(controlView: self, didSliderTapped: value)
    }
}
