//
//  AudioPlayerSliderView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/11/25.
//

import UIKit
protocol AudioPlayerSliderDelegate:NSObjectProtocol {
    func sliderTouchBegan(value:Float)
    func sliderValueChanged(value:Float)
    func sliderTouchEnded(value:Float)
    func sliderTapped(value:Float)
}
class AudioPlayerSliderView: UIView {

    weak var delegate:AudioPlayerSliderDelegate?
    
    /// 轨道背景色
    var maximumTrackTintColor:UIColor? {
        didSet {
            trackProgressView.backgroundColor = maximumTrackTintColor
        }
    }
    /// 进度背景色
    var minmunTrackTintColor:UIColor?{
        didSet {
            sliderProgressView.backgroundColor = minmunTrackTintColor
        }
    }
    /// 缓存进度背景色
    var bufferTrackTintColor:UIColor? {
        didSet {
            bufferProgressView.backgroundColor = bufferTrackTintColor
        }
    }
    
    /// 轨道图片
    var maximumTrackImage:UIImage?{
        didSet {
            trackProgressView.image = maximumTrackImage
            maximumTrackTintColor = .clear
        }
    }
    /// 进度图片
    var minmunTrackImage:UIImage?{
        didSet {
            sliderProgressView.image = minmunTrackImage
            minmunTrackTintColor = .clear
        }
    }
    /// 缓存进度图片
    var bufferTrackImage:UIImage? {
        didSet {
            bufferProgressView.image = bufferTrackImage
            bufferTrackTintColor = .clear
        }
    }
    
    /// 小滑块的图片
    var thumbImage:UIImage? {
        didSet {
            sliderButton.setBackgroundImage(thumbImage, for: .normal)
            sliderButton.setBackgroundImage(thumbImage, for: .highlighted)
            sliderButton.sizeToFit()
        }
    }
    
    /// 进度
    var value:Float = 0.0 {
        didSet {
            
            let finishValue = trackProgressView.width * CGFloat(value)
            sliderProgressView.width = finishValue
            
            let buttonX = (self.width - self.sliderButton.width) * CGFloat(value)
            self.sliderButton.x = buttonX
            
            self.lastPoint = self.sliderButton.center
            
        }
    }
    /// 缓存进度
    var bufferValue:Float = 0.0 {
        didSet {
            let finishValue = self.trackProgressView.width * CGFloat(bufferValue)
            self.bufferProgressView.width = finishValue
        }
    }
    
    /// 是否允许点击 默认允许
    var isAllowTap:Bool = true {
        didSet {
            if !isAllowTap {
                self.removeGestureRecognizer(tapGesture)
            }
        }
    }
    /// 滑竿高度 默认 2
    var sliderHeight:CGFloat = 2 {
        didSet {
            trackProgressView.height = oldValue
            bufferProgressView.height = oldValue
            sliderProgressView.height = oldValue
        }
    }
    
    /// 轨道视图
    private lazy var trackProgressView = UIImageView()
    /// 缓存进度视图
    private lazy var bufferProgressView = UIImageView()
    /// 滑动进度视图
    private lazy var sliderProgressView = UIImageView()
    /// 滑块
    private lazy var sliderButton = AudioPlayerSliderButton()
    
    private lazy var lastPoint:CGPoint = .zero
    private var tapGesture:UITapGestureRecognizer!
    
    private let kProgressMargin:CGFloat = 2
    private let kProgressHeight:CGFloat = 2
    private let kSliderButtonHeight:CGFloat = 19
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        
        trackProgressView.clipsToBounds = true
        bufferProgressView.clipsToBounds = true
        sliderProgressView.clipsToBounds = true
        
        addSubview(trackProgressView)
        addSubview(bufferProgressView)
        addSubview(sliderProgressView)
        addSubview(sliderButton)
        sliderButton.hideAnimation()
        
        sliderButton.addTarget(self, action: #selector(sliderBtnTouchBegin(sender:)), for: .touchDown)
        sliderButton.addTarget(self, action: #selector(sliderBtnTouchEnded(sender:)), for: .touchCancel)
        sliderButton.addTarget(self, action: #selector(sliderBtnTouchEnded(sender:)), for: .touchUpInside)
        sliderButton.addTarget(self, action: #selector(sliderBtnTouchEnded(sender:)), for: .touchUpOutside)
        sliderButton.addTarget(self, action: #selector(sliderBtnDragMoving(sender:event:)), for: .touchDragInside)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(taped(gesture:)))
        self.addGestureRecognizer(tapGesture)
        
        sliderButton.frame = CGRect(x: 0, y: 0, width: kSliderButtonHeight, height: kSliderButtonHeight)
        sliderProgressView.frame = CGRect(x: kProgressMargin, y: 0, width: 0, height: kProgressHeight)
        bufferProgressView.frame = CGRect(x: kProgressMargin, y: 0, width: 0, height: kProgressHeight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        trackProgressView.frame = CGRect(x: kProgressMargin, y: 0, width: self.width - kProgressMargin * 2, height: kProgressHeight)
        trackProgressView.centerY = self.height * 0.5
        
        bufferProgressView.centerY = self.height * 0.5
        
        sliderProgressView.centerY = self.height * 0.5
        
        sliderButton.centerY = self.height * 0.5
    }
    
    @objc private func taped(gesture:UIGestureRecognizer) {
        let point = gesture.location(in: self)
        
        var value = (point.x - self.trackProgressView.left) / self.trackProgressView.width
        value = value >= 1 ? 1 : ( value <= 0 ? 0 :  value)
        self.value = Float(value)
        
        self.delegate?.sliderTapped(value: Float(value))
    }
    
    func showLoading() {
        sliderButton.showAnimation()
    }
    
    func hideLoading() {
        sliderButton.hideAnimation()
    }
    
    func showSlider() {
        sliderButton.isHidden = false
    }
    
    func hideSlider() {
        sliderButton.isHidden = true
    }
    
    //MARK 滑块事件
    @objc private func sliderBtnTouchBegin(sender:AudioPlayerSliderButton) {
        self.delegate?.sliderTouchBegan(value: value)
    }
    @objc private func sliderBtnTouchEnded(sender:AudioPlayerSliderButton) {
        self.delegate?.sliderTouchEnded(value: value)
    }
    @objc private func sliderBtnDragMoving(sender:AudioPlayerSliderButton,event:UIEvent) {
        guard let point = event.allTouches?.first?.location(in: self) else { return }
        
        var value = (point.x - sender.width * 0.5) / (self.width - sender.width)
        value = value >= 1 ? 1 : (value <= 0 ? 0 : value)
        self.value = Float(value)
        
        self.delegate?.sliderValueChanged(value: Float(value))
    }

}


class AudioPlayerSliderButton: UIButton {
    lazy var indicatorView:UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(indicatorView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorView.frame = self.bounds
        indicatorView.transform = CGAffineTransform.init(scaleX: 0.6, y: 0.6)
    }
    
    func showAnimation() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    func hideAnimation() {
        indicatorView.isHidden = true
        indicatorView.stopAnimating()
    }
}
