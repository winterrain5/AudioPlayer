//
//  AudioPlayerControlView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit

protocol AudioPlayerControlViewDelegate:NSObjectProtocol {
    
    // 按钮点击
    func controlView(controlView:AudioPlayerControlView, didClickLoop:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickPrev:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickPlay:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickNext:UIButton)
    func controlView(controlView:AudioPlayerControlView, didClickList:UIButton)
    
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
    
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var preButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    
    @IBOutlet weak var sliderContainer: UIView!
    
    lazy var sliderView:AudioPlayerSliderView = {
        let view = AudioPlayerSliderView()
        view.delegate = self
        view.bufferTrackImage = UIImage(named: "cm2_fm_playbar_ready")
        view.minmunTrackImage = UIImage(named: "cm2_fm_playbar_curr")
        view.maximumTrackImage = UIImage(named: "cm2_fm_playbar_bg")
        view.thumbImage = UIImage(named: "cm2_fm_playbar_btn")
        view.sliderHeight = 2
        
        return view
    }()
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sliderContainer.addSubview(sliderView)
        sliderView.value = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.frame = CGRect(x: 0, y: 0, width: self.width - 120, height: 30)
    }
    
    @IBAction func loopAction(_ sender: UIButton) {
        self.delegate?.controlView(controlView: self, didClickLoop: sender)
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
    @IBAction func listAction(_ sender: UIButton) {
        self.delegate?.controlView(controlView: self, didClickList: sender)
    }
    
    func setupPlayBtn() {
        playButton.setImage(UIImage(named: "cm2_fm_btn_pause"), for: .normal)
    }
    
    func setupPauseBtn() {
        playButton.setImage(UIImage(named: "cm2_fm_btn_play"), for: .normal)
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
