//
//  VideoPlayControlView.swift
//  AudioPlayer
//
//  Created by VICTOR03 on 2020/12/7.
//

import UIKit
import ZFPlayer
class VideoPlayControlView: UIView,ZFPlayerMediaControl {
    var player: ZFPlayerController?
    /// 控制层自动隐藏的时间，默认2.5秒
    let autoHiddenTimeInterval:TimeInterval = 5
    /// 控制层显示、隐藏动画的时长，默认0.25秒
    let autoFadeTimeInterval:TimeInterval = 0.25
    lazy var bottomGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        let startColor = UIColor.black.withAlphaComponent(0.02).cgColor
        let endColor = UIColor.black.withAlphaComponent(0.8).cgColor
        l.colors = [startColor,endColor]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint = CGPoint(x:0.5, y: 1)
        l.locations = [0,1]
        return l
    }()
    lazy var topGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        let startColor = UIColor.black.withAlphaComponent(0.8).cgColor
        let endColor = UIColor.black.withAlphaComponent(0.02).cgColor
        l.colors = [startColor,endColor]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint = CGPoint(x:0.5, y: 1)
        l.locations = [0,1]
        return l
    }()
    /// 底部工具栏
    lazy var bottomToolView = UIView()
    /// 顶部工具栏
    lazy var topToolView = UIView()
    /// 标题
    lazy var titleLabel = UILabel().then { (label) in
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
    }
    /// 返回按钮
    lazy var backButton = UIButton().then { (button) in
        button.setImage(UIImage(named: "video_back_button"), for: .normal)
    }
    /// 播放或暂停按钮
    lazy var playOrPauseButton = UIButton().then { (button) in
        button.setImage(UIImage(named: "video_play_big"), for: .normal)
        button.setImage(UIImage(named: "video_pause_big"), for: .selected)
        button.contentMode = .right
    }
    /// 滑竿
    lazy var slider = ZFSliderView().then { (slider) in
        slider.delegate = self
        slider.maximumTrackImage = UIImage(named: "slider_track")
        slider.bufferTrackTintColor = .clear
        slider.minimumTrackImage = UIImage(named: "slider_progress")
        slider.sliderBtn.setBackgroundImage(UIImage(named: "slider_dot"), for: .normal)
        
    }
    /// 视频总时间
    lazy var totalTimeLabel = UILabel().then { (label) in
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
    }
    /// 当前播放的时长
    lazy var currentTimeLabel = UILabel().then { (label) in
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
    }
    /// 全屏按钮
    lazy var fullScreenButton = UIButton().then { (button) in
        button.setImage(UIImage(named: "video_full_screen"), for: .normal)
        button.setImage(UIImage(named: "video_exist_full_screen"), for: .selected)
    }
    /// 加载loading
    lazy var activity = ZFSpeedLoadingView()
    /// 封面图
    lazy var coverImageView = UIImageView().then { (imageView) in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    /// 底图图
    lazy var backgroundImageView = UIImageView().then { (imageView) in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    lazy var blurView = UIVisualEffectView().then { (view) in
        let effect = UIBlurEffect(style: .dark)
        let vibrance = UIVibrancyEffect(blurEffect: effect)
        view.effect = effect
    }
    /// 倍速按钮
    lazy var rateButton = UIButton().then { (button) in
        button.setTitle("倍速", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
    }
    /// 倍速视图
    lazy var rateCoverView = VideoRateView()
    
    /// 是否显示controlView
    lazy var isShow:Bool = false
    lazy var controlViewAppeared:Bool = false
    
    var afterBlock:DispatchWorkItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundImageView)
        backgroundImageView.addSubview(blurView)
        
        addSubview(topToolView)
        topToolView.layer.addSublayer(topGradientLayer)
        
        topToolView.addSubview(titleLabel)
        topToolView.addSubview(backButton)
        
        addSubview(bottomToolView)
        bottomToolView.layer.addSublayer(bottomGradientLayer)
        
        bottomToolView.addSubview(playOrPauseButton)
        bottomToolView.addSubview(currentTimeLabel)
        bottomToolView.addSubview(slider)
        bottomToolView.addSubview(totalTimeLabel)
        bottomToolView.addSubview(rateButton)
        bottomToolView.addSubview(fullScreenButton)
        
        rateCoverView.alpha = 0
        addSubview(rateCoverView)
        
        addActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 添加响应事件
    func addActions() {
        playOrPauseButton.addTarget(self, action: #selector(playPauseButtonClickAction(_:)), for: .touchUpInside)
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonClickAction(_:)), for: .touchUpInside)
        rateButton.addTarget(self, action: #selector(rateButtonClickAction(_:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(fullScreenButtonClickAction(_:)), for: .touchUpInside)
        
        rateCoverView.rateSelectComplete = { [weak self] rate in
            guard let `self` = self else { return }
            self.player?.currentPlayerManager.rate = rate
            self.rateButton.setTitle("\(rate)x", for: .normal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let player = self.player else { return }
        if player.isFullScreen {
            landscapLayout()
        }else {
            portraitLayout()
        }
        
    }
    
    @objc func rateButtonClickAction(_ sender:UIButton) {
        UIView.animate(withDuration: 0.2) {
            self.rateCoverView.alpha = self.rateCoverView.alpha == 0 ? 1 : 0
        }
    }
    
    @objc func playPauseButtonClickAction(_ sender:UIButton) {
        playOrPause()
    }
    
    @objc func fullScreenButtonClickAction(_ sender:UIButton) {
        player?.enterFullScreen(!(self.player?.isFullScreen ?? false), animated: true)
        layoutIfNeeded()
        setNeedsLayout()
    }
    
    /// 根据当前状态取反
    func playOrPause() {
        playOrPauseButton.isSelected.toggle()
        playOrPauseButton.isSelected ? player?.currentPlayerManager.play() : player?.currentPlayerManager.pause()
    }
    
    func playBtnSelectedState(_ selected:Bool) {
        playOrPauseButton.isSelected = selected
    }
    
    func portraitLayout() {
        
        topToolView.isHidden = true
        totalTimeLabel.isHidden = false
        rateButton.isHidden = true
        fullScreenButton.isSelected = false
        
        backgroundImageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        blurView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bottomToolView.snp.remakeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(54)
        }
        bottomGradientLayer.frame = bottomToolView.bounds
        playOrPauseButton.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-11)
            make.width.height.equalTo(18)
        }
        currentTimeLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(playOrPauseButton.snp.right).offset(9)
            make.centerY.equalTo(playOrPauseButton)
        }
        
        fullScreenButton.snp.remakeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(playOrPauseButton)
            make.width.equalTo(19)
            make.height.equalTo(17)
        }

        totalTimeLabel.snp.remakeConstraints { (make) in
            make.right.equalTo(fullScreenButton.snp.left).offset(-11)
            make.centerY.equalTo(playOrPauseButton)
        }
        
        slider.sliderHeight = 2
        slider.sliderRadius = 1
        slider.thumbSize = CGSize(width: 5, height: 10)
        slider.snp.remakeConstraints { (make) in
            make.left.equalTo(currentTimeLabel.snp.right).offset(8)
            make.centerY.equalTo(playOrPauseButton)
            make.height.equalTo(12)
            make.right.equalTo(totalTimeLabel.snp.left).offset(-8)
        }
        
    }
    
    func landscapLayout() {
        
        totalTimeLabel.isHidden = true
        topToolView.isHidden = false
        rateButton.isHidden = false
        fullScreenButton.isSelected = true
        
        backgroundImageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        blurView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bottomToolView.snp.remakeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(68 + kBottomsafeAreaMargin)
        }
        bottomGradientLayer.frame = bottomToolView.bounds
        
        topToolView.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(68)
        }
        topGradientLayer.frame = topToolView.bounds
        
        rateCoverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        if iPhoneX() {
            
            backButton.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(kTopsafeAreaMargin)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(30)
            }
            
            playOrPauseButton.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(kTopsafeAreaMargin)
                make.bottom.equalToSuperview().offset(-24)
                make.width.height.equalTo(21)
            }
          
            
            fullScreenButton.snp.remakeConstraints { (make) in
                make.right.equalToSuperview().offset(-kBottomsafeAreaMargin)
                make.centerY.equalTo(playOrPauseButton)
                make.width.equalTo(26)
                make.height.equalTo(21)
            }
            
            
        }else {
            
            backButton.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(30)
            }
            
            playOrPauseButton.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(15)
                make.bottom.equalToSuperview().offset(-24)
                make.width.height.equalTo(21)
            }
          
            
            fullScreenButton.snp.remakeConstraints { (make) in
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalTo(playOrPauseButton)
                make.width.equalTo(26)
                make.height.equalTo(21)
            }
            
        }
        
        rateButton.snp.remakeConstraints { (make) in
            make.right.equalTo(fullScreenButton.snp.left).offset(-16)
            make.centerY.equalTo(playOrPauseButton)
            make.width.equalTo(35)
            make.height.equalTo(19)
        }
        
        
        slider.sliderHeight = 4
        slider.sliderRadius = 2
        slider.thumbSize = CGSize(width: 8, height: 16)
        slider.snp.remakeConstraints { (make) in
            make.left.equalTo(playOrPauseButton.snp.right).offset(8)
            make.centerY.equalTo(playOrPauseButton)
            make.height.equalTo(18)
            make.right.equalTo(rateButton.snp.left).offset(-20)
        }
        
        currentTimeLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(slider)
            make.top.equalTo(slider.snp.bottom).offset(6)
        }
        
        titleLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
        }
    }
    
    func resetControlView() {
        slider.value = 0
        slider.bufferValue = 0
        currentTimeLabel.text = "00:00"
        totalTimeLabel.text = "00:00"
        playOrPauseButton.isSelected = true
        titleLabel.text = ""
    }
    
    func showControlView() {
        topToolView.alpha = 1
        bottomToolView.alpha = 1
        isShow = true
    }
    
    func hideControlView() {
        topToolView.alpha = 0
        bottomToolView.alpha = 0
        isShow = false
    }
    
    func autoFadeOutControlView() {
        
        controlViewAppeared = true
        cancelAutoFadeOutControlView()
        
        afterBlock = DispatchWorkItem(block: { [weak self] in
            self?.hideControlView(animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHiddenTimeInterval, execute: afterBlock!)
        
    }
    
    func cancelAutoFadeOutControlView() {
        if let _ = self.afterBlock {
            afterBlock?.cancel()
            afterBlock = nil
        }
        
    }
    /// 隐藏控制层
    func hideControlView(animated:Bool) {
        controlViewAppeared = false
        UIView.animate(withDuration:animated ? autoFadeTimeInterval : 0) {
            self.hideControlView()
        }
    }
    
    /// 显示控制层
    func showControlView(animated:Bool) {
        controlViewAppeared = true
        autoFadeOutControlView()
        UIView.animate(withDuration:animated ? autoFadeTimeInterval : 0) {
            self.showControlView()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isShow {
            hideControlView()
        }else {
            showControlView()
        }
    }
    
    func shouldResponseGesture(with point:CGPoint,gestureType:ZFPlayerGestureType,touch: UITouch) -> Bool{
        let sliderRect = bottomToolView.convert(slider.frame, to: self)
        if sliderRect.contains(point) {
            return false
        }
        return true
    }
    
    //MARK: ZFPlayerMediaControl
    /// 手势筛选，返回NO不响应该手势
    func gestureTriggerCondition(_ gestureControl: ZFPlayerGestureControl, gestureType: ZFPlayerGestureType, gestureRecognizer: UIGestureRecognizer, touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        guard let player = self.player else { return false }
        if player.isSmallFloatViewShow && !player.isFullScreen && gestureType != .singleTap {
            return false
        }
        return self.shouldResponseGesture(with: point, gestureType: gestureType, touch: touch)
    }
    
    // 单击手势
    func gestureSingleTapped(_ gestureControl: ZFPlayerGestureControl) {
        guard let player = self.player else { return }
        if player.isSmallFloatViewShow && !player.isFullScreen {
            player.enterFullScreen(true, animated: true)
        }else {
            if controlViewAppeared {
                hideControlView(animated: true)
            }else {
                // 显示之前先把控制层复位 先隐藏后显示
                hideControlView(animated: false)
                showControlView(animated: true)
            }
        }
        if player.isFullScreen && rateCoverView.alpha == 1{
            rateCoverView.alpha = 0
        }
    }
    
    // 双击
    func gestureDoubleTapped(_ gestureControl: ZFPlayerGestureControl) {
        playOrPause()
        if !controlViewAppeared {
            hideControlView(animated: false)
            showControlView(animated: true)
        }
    }
    
    // 准备播放
    func videoPlayer(_ videoPlayer: ZFPlayerController, prepareToPlay assetURL: URL) {
        hideControlView(animated: false)
    }
    
    // 播放状态改变
    func videoPlayer(_ videoPlayer: ZFPlayerController, playStateChanged state: ZFPlayerPlaybackState) {
        switch state {
        case .playStatePlaying:
            playBtnSelectedState(true)
            if videoPlayer.currentPlayerManager.loadState == .stalled ||
                videoPlayer.currentPlayerManager.loadState == .prepare{
                activity.startAnimating()
            }
        case .playStatePaused:
            playBtnSelectedState(false)
            activity.stopAnimating()
        case .playStatePlayStopped:
            playBtnSelectedState(false)
            activity.stopAnimating()
            showControlView(animated: false)
        case .playStatePlayFailed:
            activity.stopAnimating()
        default:
            activity.stopAnimating()
        }
    }
    
    // 加载状态改变
    func videoPlayer(_ videoPlayer: ZFPlayerController, loadStateChanged state: ZFPlayerLoadState) {
        if state == .prepare {
            coverImageView.isHidden = false
        }else if state == .playthroughOK || state == .playable {
            coverImageView.isHidden = true
            videoPlayer.currentPlayerManager.view.backgroundColor = .clear
        }
        if state == .stalled && videoPlayer.currentPlayerManager.isPlaying {
            activity.startAnimating()
        }else if (( state == .stalled || state == .prepare) && videoPlayer.currentPlayerManager.isPlaying ) {
            activity.startAnimating()
        }else {
            activity.stopAnimating()
        }
    }
    
    // 播放进度改变
    func videoPlayer(_ videoPlayer: ZFPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {

        if !slider.isdragging {
            let currenttimeString = Float(currentTime).converTimeSecond
        
            let totaltimeString = Float(totalTime).converTimeSecond
            totalTimeLabel.text = totaltimeString
            
            slider.value = videoPlayer.progress
            
            if videoPlayer.isFullScreen {
                currentTimeLabel.text = "\(currenttimeString)/\(totaltimeString)"
            }else {
                currentTimeLabel.text = currenttimeString
            }
        }
    }
    
    // 缓冲改变
    func videoPlayer(_ videoPlayer: ZFPlayerController, bufferTime: TimeInterval) {
        slider.bufferValue = videoPlayer.bufferProgress
    }
    
    // 视频view即将旋转
    func videoPlayer(_ videoPlayer: ZFPlayerController, orientationWillChange observer: ZFOrientationObserver) {
        if videoPlayer.isSmallFloatViewShow {
            if observer.isFullScreen {
                controlViewAppeared = false
                cancelAutoFadeOutControlView()
            }
        }
        if controlViewAppeared {
            showControlView(animated: false)
        }else {
            hideControlView(animated: false)
        }
        layoutIfNeeded()
        setNeedsLayout()
    }
    
    // 视频view 已经旋转
    func videoPlayer(_ videoPlayer: ZFPlayerController, orientationDidChanged observer: ZFOrientationObserver) {
        if controlViewAppeared {
            showControlView(animated: false)
        }else{
            hideControlView(animated: false)
        }
        layoutIfNeeded()
        setNeedsLayout()
    }
}

extension VideoPlayControlView:ZFSliderViewDelegate {
    func sliderTouchBegan(_ value: Float) {
        slider.isdragging = true
    }
    func sliderTouchEnded(_ value: Float) {
        guard let player = self.player else { return }
        if player.totalTime > 0 {
            player.seek(toTime: player.totalTime * Double(value)) { [weak self] (finished) in
                if finished {
                    self?.slider.isdragging = false
                }
            }
        }else {
            self.slider.isdragging = false
        }
        autoFadeOutControlView()
    }
    func sliderValueChanged(_ value: Float) {
        guard let player = self.player else { return }
        if player.totalTime == 0 {
            slider.value = 0
            return
        }
        slider.isdragging = true
        let currenttimeString = value.converTimeSecond
        currentTimeLabel.text = currenttimeString
        cancelAutoFadeOutControlView()
    }
    
    func sliderTapped(_ value: Float) {
        guard let player = self.player else { return }
        if player.totalTime > 0 {
            slider.isdragging = true
            player.seek(toTime: player.totalTime * Double(value)) { [weak self] (finished) in
                if finished {
                    self?.slider.isdragging = false
                    self?.player?.currentPlayerManager.play()
                }
            }
        }else {
            slider.isdragging = false
            slider.value = 0
        }
    }
    
}



// MARK: Public funciton
extension VideoPlayControlView {
    func show(title: String,placeHolder:UIImage,coverUrlStr:String,fullScreenModel:ZFFullScreenMode) {
        resetControlView()
        layoutIfNeeded()
        setNeedsLayout()
        titleLabel.text = title
        player?.orientationObserver.fullScreenMode = fullScreenModel
        player?.currentPlayerManager.view.coverImageView.setImageWithURLString(coverUrlStr, placeholder: placeHolder)
        backgroundImageView.image = placeHolder
        player?.currentPlayerManager.view.insertSubview(backgroundImageView, at: 0)
    }
}

extension Float{
    var converTimeSecond: String {
        let second = Int(self)
        if second < 60 {
            return String(format: "00:%02zd", second)
        }
        if second >= 60 && second < 3600 {
            return String(format: "%02zd:%02zd", second/60,second%60)
        }
        if second >= 3600 {
            return String(format: "%02zd:%02zd:%02zd", second/3600,second%3600/60,second%60)
        }
        return "00:00"
    }
}
